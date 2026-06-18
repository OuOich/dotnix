{
  networking = {
    defaultGateway = {
      interface = "ens18";
      address = "156.239.8.129";
    };

    interfaces = {
      ens18 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "156.239.8.225";
            prefixLength = 24;
          }
        ];
      };
    };
  };
}
