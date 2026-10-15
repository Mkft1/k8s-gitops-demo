FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY NotificationService.csproj .
RUN dotnet restore
COPY . .
# Добавлены флаги для уменьшения размера финальной сборки
RUN dotnet publish -c Release -o /app/publish /p:DebugType=None /p:DebugSymbols=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine
WORKDIR /app
# Создаем пользователя с конкретным UID для соответствия securityContext в Helm
RUN addgroup -S appgroup && adduser -S appuser -G appgroup -u 1000
COPY --from=build --chown=appuser:appgroup /app/publish .
USER appuser
ENV ASPNETCORE_URLS=http://0.0.0.0:8000
ENV DOTNET_NoStatusUpdate=true
EXPOSE 8000
ENTRYPOINT ["dotnet", "NotificationService.dll"]
