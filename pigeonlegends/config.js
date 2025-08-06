// Supabase Configuratie
const SUPABASE_URL = 'https://ohxiphxkxwjvrbcatetsd.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oeGlwaHhreHdqdnJiY2F0ZXNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMzg5OTcsImV4cCI6MjA2OTgxNDk5N30.wzXFYkOUqWIaOc-J6IZoWw83xbPPGEEBTZhLrzVCtzg';

// App instellingen
const APP_SETTINGS = {
    appName: 'Pigeon Legends',
    version: '1.0.0',
    language: 'nl',
    currency: 'EUR'
};

// Geolocatie functie voor alle pagina's
function getLocationFromAddress(address) {
    const locations = {
        'Oostakker, België': { lat: 51.0500, lng: 3.7500 },
        'Sas van Gent, Nederland': { lat: 51.2275, lng: 3.7997 },
        'Mendonk, België': { lat: 51.1500, lng: 3.8000 },
        'Gent, België': { lat: 51.0500, lng: 3.7300 },
        'Antwerpen, België': { lat: 51.2200, lng: 4.4100 },
        'Brussel, België': { lat: 50.8500, lng: 4.3500 }
    };
    
    return locations[address] || { lat: 51.0500, lng: 3.7500 };
}

// User management functies - Vereenvoudigd en consistent
function getCurrentUser() {
    const email = localStorage.getItem('currentUserEmail');
    const firstName = localStorage.getItem('userFirstName') || '';
    const lastName = localStorage.getItem('userLastName') || '';
    const location = localStorage.getItem('userLocation') || '';
    
    return email ? { 
        email: email, 
        firstName: firstName, 
        lastName: lastName, 
        location: location 
    } : null;
}

function setCurrentUser(user) {
    localStorage.setItem('currentUserEmail', user.email);
    if (user.firstName) localStorage.setItem('userFirstName', user.firstName);
    if (user.lastName) localStorage.setItem('userLastName', user.lastName);
    if (user.location) localStorage.setItem('userLocation', user.location);
}

function clearCurrentUser() {
    localStorage.removeItem('currentUserEmail');
    localStorage.removeItem('userFirstName');
    localStorage.removeItem('userLastName');
    localStorage.removeItem('userLocation');
}

// Notification functie
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 5px;
        color: white;
        z-index: 1000;
        font-weight: bold;
    `;
    
    if (type === 'error') notification.style.backgroundColor = '#e74c3c';
    else if (type === 'success') notification.style.backgroundColor = '#27ae60';
    else notification.style.backgroundColor = '#3498db';
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 3000);
}