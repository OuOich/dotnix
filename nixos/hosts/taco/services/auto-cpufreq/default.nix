{
  services.auto-cpufreq = {
    enable = true;

    settings = {
      battery = {
        enable_thresholds = true;
        start_threshold = 70;
        stop_threshold = 80;
      };
    };
  };
}
