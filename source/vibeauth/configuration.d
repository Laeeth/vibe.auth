/++
  A module containing the configuration structures used to setup your auth process

  Copyright: © 2018 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/
module vibeauth.configuration;

struct ServiceConfiguration {
  string name = "Unknown App";
  string location = "http://localhost";
  string style;
}

struct RegistrationConfiguration {
	RegistrationConfigurationPaths paths;
	RegistrationConfigurationTemplates templates;
}

struct RegistrationConfigurationPaths {
	string register = "/register";
	string addUser = "/register/user";
	string activation = "/register/activation";
	string challange = "/register/challenge";
	string confirmation = "/register/confirmation";
	string activationRedirect = "/";
}

struct RegistrationConfigurationTemplates {
	string form;
	string confirmation;
	string success;
}

struct LoginConfigurationPaths {
	string form = "/login";
	string login = "/login/check";

	string resetForm = "/login/reset";
	string reset = "/login/reset/send";

  string changePassword =  "/login/reset/change";

	string redirect = "/";
}

struct LoginConfigurationTemplates {
	string login;
	string reset;
}

struct LoginConfiguration {
	LoginConfigurationPaths paths;
	LoginConfigurationTemplates templates;

	ulong loginTimeoutSeconds = 86_400;
}
