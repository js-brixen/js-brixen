/**
 * JS Brixen - Projects Firestore Integration
 * Fetches projects from Firestore and initializes the projects page
 */

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import { getFirestore, collection, getDocs, query, where, doc, updateDoc, increment } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

// Firebase configuration
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
let app;
try {
    app = initializeApp(firebaseConfig);
} catch (error) {
    console.error('Firebase initialization error:', error);
}

const db = getFirestore(app);

// Fetch projects from Firestore
export async function fetchProjects() {
    try {
        console.log('Fetching projects from Firestore...');

        // Query only live projects for public website
        // Note: Removed orderBy to avoid composite index requirement
        const projectsQuery = query(
            collection(db, 'projects'),
            where('status', '==', 'live')
        );

        const snapshot = await getDocs(projectsQuery);

        const projects = snapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                slug: data.slug || '',
                title: data.title || '',
                district: data.district || '',
                type: data.type || 'new',
                summary: data.summary || '',
                description: data.description || '',
                images: data.images || [],
                isFeatured: data.isFeatured || false,
                tags: data.tags || [],
                views: data.views || 0,
                createdAt: data.createdAt?.toDate() || new Date(),
                meta: data.meta || {}
            };
        });

        // Sort client-side by createdAt descending (newest first)
        projects.sort((a, b) => b.createdAt - a.createdAt);

        console.log(`✅ Loaded ${projects.length} live projects from Firestore`);
        return projects;
    } catch (error) {
        console.error('❌ Error fetching projects:', error);
        return [];
    }
}

// Increment project view count
export async function incrementProjectViews(projectId) {
    try {
        const projectRef = doc(db, 'projects', projectId);
        await updateDoc(projectRef, {
            views: increment(1)
        });
        console.log(`✅ Incremented views for project: ${projectId}`);
    } catch (error) {
        console.error('❌ Error incrementing views:', error);
    }
}

// Track booking conversion from project
export async function trackProjectConversion(projectId) {
    try {
        const projectRef = doc(db, 'projects', projectId);
        await updateDoc(projectRef, {
            bookingConversions: increment(1)
        });
        console.log(`✅ Tracked conversion for project: ${projectId}`);
    } catch (error) {
        console.error('❌ Error tracking conversion:', error);
    }
}

