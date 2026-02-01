/**
 * Services Firestore Integration
 * Fetches live services from Firebase Firestore
 */

import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.1.0/firebase-app.js';
import { getFirestore, collection, getDocs, query, where } from 'https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js';

console.log('[Services-Firestore] Module loaded, initializing Firebase...');

// Firebase Configuration (Same as customer-auth.js)
const firebaseConfig = {
    apiKey: "AIzaSyBmE3dzzcbMXaustT4SBjhELZ4GWR9JKlU",
    authDomain: "js-construction-811e4.firebaseapp.com",
    projectId: "js-construction-811e4",
    storageBucket: "js-construction-811e4.firebasestorage.app",
    messagingSenderId: "465344186766",
    appId: "1:465344186766:web:382584d5d07ae059e03cdf",
    measurementId: "G-K1K5B5WHV8"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

/**
 * Fetch all live services from Firestore
 * @returns {Promise<Array>} Array of service objects
 */
export async function fetchLiveServices() {
    try {
        console.log('[Services] Fetching services from Firestore...');

        const servicesRef = collection(db, 'services');
        // DEBUG: Querying strictly for status 'live'
        const q = query(
            servicesRef,
            where('status', '==', 'live')
        );

        console.log('[DEBUG] Executing Firestore Query: services where status == "live"');
        const querySnapshot = await getDocs(q);

        console.log(`[DEBUG] Query returned ${querySnapshot.size} documents.`);
        const services = [];

        querySnapshot.forEach((doc) => {
            const data = doc.data();
            console.log(`[DEBUG] Found Service: ${doc.id}, Status: ${data.status}, Title: ${data.title}`);
            services.push({
                id: doc.id,
                slug: data.slug || '',
                title: data.title || '',
                shortDescription: data.shortDescription || '',
                fullDescription: data.fullDescription || '',
                images: (data.images || []).map(img => img.url || img),
                tags: data.tags || [],
                features: data.features || [],
                process: data.process || [],
                faqs: data.faqs || [],
                areaServed: data.areaServed || [],
                status: data.status || 'disabled',
                createdAt: data.createdAt?.toDate() || new Date(),
                updatedAt: data.updatedAt?.toDate() || new Date(),
                seo: {
                    metaTitle: `${data.title} | JS Brixen`,
                    metaDescription: data.shortDescription || data.fullDescription?.substring(0, 160) || '',
                }
            });
        });

        // Sort client-side by createdAt descending (newest first)
        services.sort((a, b) => b.createdAt - a.createdAt);

        console.log(`✅ Loaded ${services.length} live services from Firestore`);
        return services;
    } catch (error) {
        console.error('❌ Error fetching services:', error);
        console.error('Error Details:', error.code, error.message); // Log exact firebase error
        return [];
    }
}

/**
 * Fetch a single service by slug
 * @param {string} slug - Service slug
 * @returns {Promise<Object|null>} Service object or null
 */
export async function fetchServiceBySlug(slug) {
    try {
        const servicesRef = collection(db, 'services');
        const q = query(servicesRef, where('slug', '==', slug));
        const querySnapshot = await getDocs(q);

        if (querySnapshot.empty) {
            console.warn(`[Firestore] No service found with slug: ${slug}`);
            return null;
        }

        const doc = querySnapshot.docs[0];
        const data = doc.data();

        return {
            id: doc.id,
            slug: data.slug || '',
            title: data.title || '',
            shortDescription: data.shortDescription || '',
            fullDescription: data.fullDescription || '',
            images: (data.images || []).map(img => img.url || img),
            tags: data.tags || [],
            features: data.features || [],
            process: data.process || [],
            faqs: data.faqs || [],
            areaServed: data.areaServed || [],
            status: data.status || 'disabled',
            createdAt: data.createdAt?.toDate() || new Date(),
            updatedAt: data.updatedAt?.toDate() || new Date(),
            seo: {
                metaTitle: `${data.title} | JS Brixen`,
                metaDescription: data.shortDescription || data.fullDescription?.substring(0, 160) || '',
            }
        };
    } catch (error) {
        console.error('[Firestore] Error fetching service by slug:', error);
        return null;
    }
}

