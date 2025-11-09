{
 services = {
  headscale = {
   enable = true;
   port = 3009;
   settings = {
	#server_url = "https://tamereenshort.com"
	#dns = {
	 #base_domain = #"shorts.loc";
	#};
     logtail.enabled = false;
    };
   };
  };
 };
}
