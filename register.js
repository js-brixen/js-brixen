// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU",
    authDomain: "js-construction-811e4.firebaseapp.com",
    projectId: "js-construction-811e4",
    storageBucket: "js-construction-811e4.firebasestorage.app",
    messagingSenderId: "465344186766",
    appId: "1:465344186766:web:382584d5d07ae059e03cdf",
    measurementId: "G-K1K5B5WHV8"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);