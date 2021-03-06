module vibeauth.mail.vibe;

import vibe.mail.smtp;
import vibe.inet.message;
import vibe.stream.tls;

import vibeauth.mail.base;
import vibeauth.users;
import vibeauth.token;

import std.process;
import std.stdio;
import std.string;
import std.conv;
import std.datetime;

class VibeMailQueue : MailQueue {

	private {
		SMTPClientSettings smtpSettings;
	}

	this(EmailConfiguration settings) {
		super(settings);

		smtpSettings = new SMTPClientSettings(settings.smtp.host, settings.smtp.port);

		smtpSettings.authType = settings.smtp.authType.to!SMTPAuthType;
		smtpSettings.connectionType = settings.smtp.connectionType.to!SMTPConnectionType;
		smtpSettings.tlsValidationMode = settings.smtp.tlsValidationMode.to!TLSPeerValidationMode;
		smtpSettings.tlsVersion = settings.smtp.tlsVersion.to!TLSVersion;

		smtpSettings.localname = settings.smtp.localname;
		smtpSettings.password = settings.smtp.password;
		smtpSettings.username = settings.smtp.username;
	}

	override void addMessage(Message message) {
		send(message);
	}

	private void send(Message message) {

		foreach(to; message.to) {
			Mail email = new Mail;

			email.headers["Date"] = Clock.currTime.toRFC822DateTimeString;
			email.headers["Sender"] = message.from;
			email.headers["From"] = message.from;
			email.headers["To"] = to;
			email.headers["Subject"] = message.subject;

			foreach(header; message.headers) {
				auto index = header.indexOf(':');
				email.headers[header[0..index]] = header[index+1..$].strip;
			}

			email.bodyText = message.mailBody;

			sendMail(smtpSettings, email);
		}
	}
}
