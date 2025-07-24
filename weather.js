// Shared weather module for consistent weather across all pages
class WeatherManager {
  constructor() {
    this.weatherData = null;
    this.lastUpdate = 0;
    this.updateInterval = 5 * 60 * 1000; // 5 minutes
    this.location = 'Gent, België';
    this.timezone = 'Europe/Brussels';
    this.init();
  }

  init() {
    // Load weather from localStorage or generate new
    const savedWeather = localStorage.getItem('sharedWeather');
    const savedTime = localStorage.getItem('weatherUpdateTime');
    
    if (savedWeather && savedTime) {
      const timeSinceUpdate = Date.now() - parseInt(savedTime);
      if (timeSinceUpdate < this.updateInterval) {
        this.weatherData = JSON.parse(savedWeather);
      } else {
        this.generateNewWeather();
      }
    } else {
      this.generateNewWeather();
    }
  }

  generateNewWeather() {
    // Generate realistic weather data for Gent, Belgium
    const weatherTypes = [
      { desc: 'Zonnig', icon: '☀️', tempRange: [15, 25] },
      { desc: 'Bewolkt', icon: '⛅', tempRange: [10, 20] },
      { desc: 'Regen', icon: '🌧️', tempRange: [8, 18] },
      { desc: 'Windig', icon: '💨', tempRange: [12, 22] },
      { desc: 'Mistig', icon: '🌫️', tempRange: [5, 15] },
      { desc: 'Onweer', icon: '⛈️', tempRange: [12, 25] },
      { desc: 'Licht bewolkt', icon: '🌤️', tempRange: [12, 22] },
      { desc: 'Druilerig', icon: '🌦️', tempRange: [10, 18] }
    ];

    const selectedWeather = weatherTypes[Math.floor(Math.random() * weatherTypes.length)];
    const temp = Math.floor(Math.random() * (selectedWeather.tempRange[1] - selectedWeather.tempRange[0] + 1)) + selectedWeather.tempRange[0];

    // Get current time in Gent timezone
    const now = new Date();
    const gentTime = new Date(now.toLocaleString("en-US", {timeZone: this.timezone}));
    
    this.weatherData = {
      temp: temp,
      desc: selectedWeather.desc,
      icon: selectedWeather.icon,
      location: this.location,
      timestamp: Date.now(),
      time: gentTime.toLocaleTimeString('nl-NL', { 
        hour: '2-digit', 
        minute: '2-digit',
        timeZone: this.timezone 
      }),
      timezone: 'CET/CEST',
      day: gentTime.toLocaleDateString('nl-NL', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric',
        timeZone: this.timezone 
      })
    };

    // Save to localStorage
    localStorage.setItem('sharedWeather', JSON.stringify(this.weatherData));
    localStorage.setItem('weatherUpdateTime', Date.now().toString());
  }

  getWeather() {
    // Check if we need to update weather
    const timeSinceUpdate = Date.now() - this.lastUpdate;
    if (timeSinceUpdate >= this.updateInterval) {
      this.generateNewWeather();
      this.lastUpdate = Date.now();
    }
    
    return this.weatherData;
  }

  updateWeatherDisplay() {
    const weatherTemp = document.getElementById('weatherTemp');
    const weatherDesc = document.getElementById('weatherDesc');
    const weatherIcon = document.getElementById('weatherIcon');
    const weatherTime = document.getElementById('weatherTime');
    const weatherDay = document.getElementById('weatherDay');
    const weatherLocation = document.getElementById('weatherLocation');
    
    // Header weather elements
    const weatherTempHeader = document.getElementById('weatherTempHeader');
    const weatherDescHeader = document.getElementById('weatherDescHeader');
    const weatherIconHeader = document.getElementById('weatherIconHeader');
    const weatherTimeHeader = document.getElementById('weatherTimeHeader');
    const weatherDayHeader = document.getElementById('weatherDayHeader');

    const weather = this.getWeather();
    
    // Update main weather widget
    if (weatherTemp && weatherDesc && weatherIcon) {
      weatherTemp.textContent = `${weather.temp}°C`;
      weatherDesc.textContent = weather.desc;
      weatherIcon.textContent = weather.icon;
    }
    
    // Update time and day if elements exist
    if (weatherTime) {
      weatherTime.textContent = `${weather.time} ${weather.timezone}`;
    }
    if (weatherDay) {
      weatherDay.textContent = weather.day;
    }
    if (weatherLocation) {
      weatherLocation.textContent = weather.location;
    }
    
    // Update header weather display
    if (weatherTempHeader && weatherDescHeader && weatherIconHeader) {
      weatherTempHeader.textContent = `${weather.temp}°C`;
      weatherDescHeader.textContent = weather.desc;
      weatherIconHeader.textContent = weather.icon;
    }
    
    // Update header time and day if elements exist
    if (weatherTimeHeader) {
      weatherTimeHeader.textContent = `${weather.time} ${weather.timezone}`;
    }
    if (weatherDayHeader) {
      weatherDayHeader.textContent = weather.day;
    }
  }

  // Force update weather (for testing)
  forceUpdate() {
    this.generateNewWeather();
    this.updateWeatherDisplay();
  }

  // Test function to manually change weather
  testWeatherChange() {
    console.log('Changing weather for testing...');
    this.generateNewWeather();
    this.updateWeatherDisplay();
    console.log('New weather:', this.weatherData);
  }
}

// Create global instance
window.weatherManager = new WeatherManager();

// Export for module usage
export { WeatherManager }; 