from email.message import EmailMessage
import logging
import smtplib

from ..config import settings

logger = logging.getLogger(__name__)


def send_password_reset_code(recipient: str, code: str) -> bool:
    if not settings.smtp_host or not settings.smtp_from_email:
        logger.error("Password reset delivery is not configured; set SMTP_HOST and SMTP_FROM_EMAIL")
        return False
    message = EmailMessage()
    message["Subject"] = "Punjabi Welfare Trust password reset code"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(f"Your Punjabi Welfare Trust password reset code is {code}. It expires in 15 minutes. If you did not request it, ignore this message.")
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as client:
        if settings.smtp_use_tls:
            client.starttls()
        if settings.smtp_username:
            client.login(settings.smtp_username, settings.smtp_password)
        client.send_message(message)
    return True
