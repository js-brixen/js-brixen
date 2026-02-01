// Script to initialize Firebase with current website content
// Run this in the browser console on your website to populate Firebase

import { db } from './init.js';
import { doc, setDoc } from 'https://www.gstatic.com/firebasejs/11.1.0/firebase-firestore.js';

async function initializeContent() {
    const initialContent = {
        hero: {
            title: 'Building Your Vision Into Reality',
            subtext: 'Premium construction services across Kerala & Karnataka. From custom homes to commercial projects, we deliver excellence with every build.',
            ctaText: 'Get Free Quote'
        },
        about: {
            story: 'Founded with a vision to transform the construction industry in Kerala and Karnataka, JS Construction has grown from a small team of passionate builders to a trusted name in residential and commercial construction.',
            statsYears: '10+',
            statsProjects: '200+',
            statsClients: '500+',
            statsTeam: '50+'
        },
        howItWorks: [
            {
                step: '1',
                title: 'Book Consultation',
                description: 'Schedule a free consultation with our experts to discuss your project requirements and vision.'
            },
            {
                step: '2',
                title: 'Contact us',
                description: 'Receive a detailed, transparent quote with no hidden costs.'
            },
            {
                step: '3',
                title: 'Get Building',
                description: 'Our experienced team begins construction with regular updates and quality checks.'
            }
        ],
        cta: {
            title: 'Ready to Start Your Project?',
            text: "Let's discuss your vision and bring it to life with expert construction services"
        },
        contact: {
            phone: '+91XXXXXXXXXX',
            phones: ['+91XXXXXXXXXX'],
            email: 'info@jsconstruction.com',
            whatsapp: '91XXXXXXXXXX'
        },
        updatedAt: new Date()
    };

    try {
        const docRef = doc(db, 'siteContent', 'main');
        await setDoc(docRef, initialContent);
        console.log('✅ Successfully initialized Firebase with website content!');
        console.log('Content:', initialContent);
        return true;
    } catch (error) {
        console.error('❌ Error initializing content:', error);
        return false;
    }
}

// Export for use
export { initializeContent };

// Auto-run if loaded as module
if (typeof window !== 'undefined') {
    window.initializeContent = initializeContent;
    console.log('🔧 Firebase initializer loaded. Run initializeContent() to set up content.');
}
