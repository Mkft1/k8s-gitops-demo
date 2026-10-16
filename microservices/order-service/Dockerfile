FROM python:3.11-slim AS builder

WORKDIR /app

# Копируем только requirements.txt для лучшего кэширования
COPY requirements.txt .

# Создаем виртуальное окружение и устанавливаем зависимости
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# Финальная стадия
FROM python:3.11-slim

WORKDIR /app

# Создаем непривилегированного пользователя
RUN useradd -m -u 1000 appuser

# Копируем виртуальное окружение с правильными правами
COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем код приложения с правильными правами
COPY --chown=appuser:appuser main.py .

# Переключаемся на непривилегированного пользователя ПОСЛЕ всех операций от root
USER appuser

ENV PYTHONUNBUFFERED=1
EXPOSE 8000

# Запускаем приложение от имени appuser
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
