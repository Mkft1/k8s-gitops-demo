using System.Text;
using System.Text.Json;
using Prometheus;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Serilog;
using Serilog.Formatting.Compact;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, config) => config
    .Enrich.WithProperty("service", "notification-service")
    .Enrich.FromLogContext()
    .WriteTo.Console(new RenderedCompactJsonFormatter()));

// Регистрация сервиса HealthChecks
builder.Services.AddHealthChecks();

builder.Services.AddHostedService<NotificationConsumer>();

var app = builder.Build();

app.MapHealthChecks("/health");
app.MapMetrics("/metrics");

app.Run();

public sealed class NotificationConsumer : BackgroundService
{
    private readonly IConfiguration _config;
    private readonly ILogger<NotificationConsumer> _logger;

    private static readonly Counter NotificationsTotal = Metrics.CreateCounter(
        "notifications_sent_total", "Total number of notifications sent", "channel");
    private static readonly Counter NotificationsFailedTotal = Metrics.CreateCounter(
        "notifications_failed_total", "Total number of failed notification attempts");

    public NotificationConsumer(IConfiguration config, ILogger<NotificationConsumer> logger)
    {
        _config = config;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var factory = new ConnectionFactory
                {
                    HostName = _config["RABBITMQ_HOST"] ?? "rabbitmq",
                    Port = int.Parse(_config["RABBITMQ_PORT"] ?? "5672"),
                    UserName = _config["RABBITMQ_USER"] ?? "orders_app",
                    Password = _config["RABBITMQ_PASSWORD"] ?? string.Empty
                };

                await using var connection = await factory.CreateConnectionAsync(stoppingToken);
                await using var channel = await connection.CreateChannelAsync(cancellationToken: stoppingToken);

                await channel.QueueDeclareAsync(
                    queue: "notifications_queue",
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    cancellationToken: stoppingToken);

                await channel.BasicQosAsync(0, 1, false, stoppingToken);

                var consumer = new AsyncEventingBasicConsumer(channel);
                consumer.ReceivedAsync += OnMessageReceived(channel);

                await channel.BasicConsumeAsync(
                    queue: "notifications_queue",
                    autoAck: false,
                    consumer: consumer,
                    cancellationToken: stoppingToken);

                _logger.LogInformation("Listening on queue {Queue}", "notifications_queue");

                await Task.Delay(Timeout.InfiniteTimeSpan, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "RabbitMQ connection failed, retry in 5 seconds");
                try { await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken); }
                catch (OperationCanceledException) { break; }
            }
        }
    }

    private AsyncEventHandler<BasicDeliverEventArgs> OnMessageReceived(IChannel channel)
    {
        return async (_, args) =>
        {
            try
            {
                var body = Encoding.UTF8.GetString(args.Body.ToArray());
                using var doc = JsonDocument.Parse(body);
                var root = doc.RootElement;

                var orderId = root.GetProperty("order_id").GetString();
                var item = root.GetProperty("item").GetString();
                var quantity = root.GetProperty("quantity").GetInt32();

                _logger.LogInformation(
                    "Notification sent: order_id={OrderId} item={Item} quantity={Quantity} channel=email",
                    orderId, item, quantity);

                NotificationsTotal.WithLabels("email").Inc();

                await channel.BasicAckAsync(args.DeliveryTag, false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process notification message");
                NotificationsFailedTotal.Inc();
                await channel.BasicNackAsync(args.DeliveryTag, false, false);
            }
        };
    }
}
