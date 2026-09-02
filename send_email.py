#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 stdin 读取 HTML 正文，通过 SMTP(SSL) 发送邮件。
用法: python3 send_email.py "邮件主题" < body.html
配置从同目录 smtp.conf 读取 (KEY=VALUE)。
"""
import sys, os, ssl, smtplib
from email.mime.text import MIMEText
from email.header import Header
from email.utils import formataddr, formatdate

def load_conf(path):
    conf = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            conf[k.strip()] = v.strip()
    return conf

def main():
    if len(sys.argv) < 2:
        print("usage: send_email.py <subject>", file=sys.stderr)
        sys.exit(2)
    subject = sys.argv[1]
    here = os.path.dirname(os.path.abspath(__file__))
    conf = load_conf(os.path.join(here, "smtp.conf"))

    host = conf.get("SMTP_HOST", "smtp.qq.com")
    port = int(conf.get("SMTP_PORT", "465"))
    user = conf["SMTP_USER"]
    pw   = conf["SMTP_PASS"]
    mfrom = conf.get("MAIL_FROM", user)
    mto  = [x.strip() for x in conf.get("MAIL_TO", "").split(",") if x.strip()]
    if not mto:
        print("MAIL_TO empty", file=sys.stderr)
        sys.exit(2)

    body = sys.stdin.read()
    msg = MIMEText(body, "html", "utf-8")
    msg["Subject"] = Header(subject, "utf-8")
    msg["From"] = formataddr((str(Header("行情简报", "utf-8")), mfrom))
    msg["To"] = ", ".join(mto)
    msg["Date"] = formatdate(localtime=True)

    ctx = ssl.create_default_context()
    with smtplib.SMTP_SSL(host, port, context=ctx, timeout=30) as s:
        s.login(user, pw)
        s.sendmail(mfrom, mto, msg.as_string())
    print("sent OK ->", ", ".join(mto))

if __name__ == "__main__":
    main()
