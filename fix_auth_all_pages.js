// Script om authenticatie te fixen op alle pagina's
// Voer dit uit in de browser console op elke pagina

// Functie om authenticatie te controleren
function checkAuth() {
    const isAuthenticated = localStorage.getItem('user_authenticated');
    const userEmail = localStorage.getItem('user_email');
    
    if (isAuthenticated !== 'true' || !userEmail) {
        window.location.href = 'login.html';
        return false;
    }
    return true;
}

// Functie om uit te loggen
function logout() {
    localStorage.removeItem('user_authenticated');
    localStorage.removeItem('user_email');
    localStorage.removeItem('user_name');
    localStorage.removeItem('team_name');
    localStorage.removeItem('login_timestamp');
    window.location.href = 'login.html';
}

// Maak logout globaal beschikbaar
window.logout = logout;

// Check authenticatie bij laden
if (checkAuth()) {
    console.log('Gebruiker is ingelogd:', localStorage.getItem('user_email'));
} 