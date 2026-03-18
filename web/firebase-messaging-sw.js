importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Firebase configuration for the Web Service Worker
firebase.initializeApp({
  apiKey: "AIzaSyAhwUr4ZGAQC9NM3yVqkacskLGlwrrdGO8",
  authDomain: "miniproject-fc41e.firebaseapp.com",
  projectId: "miniproject-fc41e",
  storageBucket: "miniproject-fc41e.firebasestorage.app",
  messagingSenderId: "339720549396",
  appId: "1:339720549396:web:79befb48c555e4a635e301"
});

const messaging = firebase.messaging();

// Handle messages in the background
messaging.onBackgroundMessage((payload) => {
  console.log("Background message:", payload);

  const notificationTitle = payload.notification?.title || "ELCB Alert";
  const notificationOptions = {
    body: payload.notification?.body || "Trip detected!",
    icon: "/icons/Icon-192.png",
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Define click action for notification
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.openWindow('/')
  );
});
