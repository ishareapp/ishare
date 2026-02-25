import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

def send_verification_email(user_email, username, code):
    """Send verification code email directly via SMTP"""
    
    sender_email = os.environ.get('EMAIL_HOST_USER', 'murenzicharles24@gmail.com')
    sender_password = os.environ.get('EMAIL_HOST_PASSWORD', '')
    
    msg = MIMEMultipart('alternative')
    msg['Subject'] = "ISHARE - Your Verification Code"
    msg['From'] = sender_email
    msg['To'] = user_email
    
    text = f"""
Hello {username},

Your ISHARE verification code is: {code}

This code expires in 10 minutes.

Made in Rwanda 🇷🇼
ISHARE Team
    """
    
    html = f"""
    <html>
    <body style="font-family: Arial, sans-serif; background-color: #f0f4ff; padding: 20px;">
        <div style="max-width: 500px; margin: auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
            
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #1E3A8A; font-size: 32px; margin: 0;">iShare</h1>
                <p style="color: #60A5FA; margin: 5px 0;">Ride Smart • Ride Together</p>
            </div>
            
            <h2 style="color: #1E3A8A;">Hello {username} 👋</h2>
            <p style="color: #555;">Use the code below to verify your email address:</p>
            
            <div style="text-align: center; margin: 30px 0;">
                <div style="background: linear-gradient(135deg, #1E3A8A, #3B82F6); color: white; font-size: 36px; font-weight: bold; letter-spacing: 10px; padding: 20px 40px; border-radius: 12px; display: inline-block;">
                    {code}
                </div>
            </div>
            
            <p style="color: #888; font-size: 13px; text-align: center;">
                ⏱ This code expires in <strong>10 minutes</strong>
            </p>
            
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            
            <p style="color: #aaa; font-size: 12px; text-align: center;">
                If you didn't request this code, please ignore this email.<br>
                Made in Rwanda 🇷🇼 | ISHARE Team
            </p>
        </div>
    </body>
    </html>
    """
    
    msg.attach(MIMEText(text, 'plain'))
    msg.attach(MIMEText(html, 'html'))
    
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587, timeout=5)  # ✅ timeout added
        server.starttls()
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, user_email, msg.as_string())
        server.quit()
        print(f"✅ Verification email sent to {user_email}")
        return True
    except Exception as e:
        print(f"❌ Email failed: {e}")
        return False


def send_welcome_email(user_email, username, role):
    """Send welcome email after registration"""
    
    sender_email = os.environ.get('EMAIL_HOST_USER', 'murenzicharles24@gmail.com')
    sender_password = os.environ.get('EMAIL_HOST_PASSWORD', '')
    
    msg = MIMEMultipart('alternative')
    msg['Subject'] = "Welcome to ISHARE! 🎉"
    msg['From'] = sender_email
    msg['To'] = user_email
    
    html = f"""
    <html>
    <body style="font-family: Arial, sans-serif; background-color: #f0f4ff; padding: 20px;">
        <div style="max-width: 500px; margin: auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
            
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #1E3A8A; font-size: 32px; margin: 0;">iShare</h1>
                <p style="color: #60A5FA; margin: 5px 0;">Ride Smart • Ride Together</p>
            </div>
            
            <h2 style="color: #1E3A8A;">Welcome {username}! 🎉</h2>
            <p style="color: #555;">You have successfully joined ISHARE — Rwanda's #1 ride sharing app!</p>
            
            <div style="background: #f0f4ff; border-radius: 12px; padding: 20px; margin: 20px 0;">
                <p style="margin: 5px 0; color: #333;"><strong>Account:</strong> {user_email}</p>
                <p style="margin: 5px 0; color: #333;"><strong>Role:</strong> {role.capitalize()}</p>
                <p style="margin: 5px 0; color: #34D399;"><strong>Trial:</strong> 30 days free ✅</p>
            </div>
            
            <p style="color: #555;">
                {"Start creating rides and earn money! 🚗" if role == "driver" else "Start booking affordable rides! 🎯"}
            </p>
            
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            
            <p style="color: #aaa; font-size: 12px; text-align: center;">
                Made in Rwanda 🇷🇼 | ISHARE Team
            </p>
        </div>
    </body>
    </html>
    """
    
    msg.attach(MIMEText(html, 'html'))
    
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587, timeout=5)  # ✅ timeout added
        server.starttls()
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, user_email, msg.as_string())
        server.quit()
        print(f"✅ Welcome email sent to {user_email}")
        return True
    except Exception as e:
        print(f"❌ Welcome email failed: {e}")
        return False