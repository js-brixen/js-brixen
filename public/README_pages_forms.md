# Pages & Forms Documentation

## Overview

This document covers the three public pages for the JS Construction website:
- **book-consultation.html** - Core lead generation form
- **contact.html** - Contact information and simple contact form
- **about.html** - Company information and values

All pages are built with plain HTML/CSS/vanilla JavaScript with **no backend implementation**. Firestore integration hooks are included as commented code for future implementation.

---

## File Structure

```
/public
├── book-consultation.html    # Booking consultation page with full form
├── contact.html              # Contact page with contact cards & form
├── about.html                # About us page with company info
├── assets/
│   ├── css/
│   │   ├── styles.css        # Base styles (existing)
│   │   ├── pages.css         # Shared page layouts (NEW)
│   │   └── forms.css         # Form-specific styles (NEW)
│   ├── js/
│   │   ├── main.js           # Navigation & header (existing)
│   │   ├── utils.js          # Helper utilities (NEW)
│   │   ├── booking.js        # Booking form logic (NEW)
│   │   └── contact.js        # Contact form logic (NEW)
│   └── img/
│       └── (placeholder images from Unsplash)
└── README_pages_forms.md     # This file
```

---

## Local Preview

To preview the pages locally:

```bash
# Option 1: Using http-server (already running)
npx -y http-server ./public -p 8080

# Option 2: Using the existing dev server
npm run dev

# Then open in browser:
# http://localhost:8080/book-consultation.html
# http://localhost:8080/contact.html
# http://localhost:8080/about.html
```

---

## Page Details

### 1. Book Consultation Page

**Purpose**: Core lead generation - collect structured consultation requests

**Key Features**:
- Hero section with CTA
- Trust row (Free Consultation, Kerala-wide, Experienced teams)
- Full booking form with validation
- FAQ accordion
- Secondary CTAs (phone, WhatsApp)

**Form Fields**:
- Personal Details: fullName*, phone*, district*
- Project Info: typeOfWork*, plotSize, budgetRange
- Preferred Slot: preferredDate, preferredTime
- Additional Notes: notes (textarea)
- Consent checkbox*
- Hidden honeypot field (anti-spam)

**Validation**:
- Inline validation with error messages
- Phone: Indian format `^(\+91[\-\s]?|0)?[6-9]\d{9}$`
- All required fields checked before submit
- Honeypot check for spam detection
- 30-second rate limit (localStorage)

**UX Flow**:
1. User fills form
2. Client-side validation
3. Submit button shows spinner
4. Success message with reference ID (e.g., `JC-20260125-1234`)
5. Options to "Book another" or "Go to Home"

**Query String Prefill**:
- `?service=turnkey-project` → prefills typeOfWork
- `?district=Ernakulam` → prefills district

---

### 2. Contact Page

**Purpose**: Provide contact information and simple message form

**Key Features**:
- Contact cards (Phone, WhatsApp, Email, Address)
- Simple contact form
- Service areas section
- Business hours table
- CTA to book consultation

**Contact Form Fields**:
- name* (min 2 chars)
- email* (valid email)
- phone (optional)
- message* (min 10 chars)

**UX Flow**:
1. User fills form
2. Validation on blur
3. Submit with spinner
4. Success message (auto-hides after 5s)

---

### 3. About Page

**Purpose**: Build trust with company information

**Key Sections**:
- Company story (2-3 paragraphs)
- Experience stats (years, projects, clients, team)
- Values (5 cards: Quality, Transparency, On-Time, Sustainability, Innovation)
- Service areas (Kerala & Karnataka)
- Quality commitments (bullet list)
- CTA section

**Placeholders for Future**:
- Team member photos
- Client testimonials
- Certifications & awards
- JSON-LD structured data (commented in `<head>`)

---

## Firestore Integration Hooks

All Firestore integration code is **commented out** with clear `TODO` markers. Look for:

```javascript
// ============================================
// FIRESTORE INTEGRATION EXAMPLE:
// ============================================
```

### Booking Form → `bookings` Collection

**Location**: `assets/js/booking.js` → `submitBooking()` function

**Fields to save**:
```javascript
{
  fullName: string,
  phone: string,
  district: string,
  typeOfWork: string,
  plotSize: string,
  budgetRange: string,
  preferredDate: string,
  preferredTime: string,
  notes: string,
  refId: string,              // Client-generated
  status: 'new',              // Default status
  source: 'website',          // Traffic source
  createdAt: serverTimestamp(),
  relatedServiceId: string | null,   // From query param
  relatedProjectId: string | null    // From query param
}
```

**Example implementation**:
```javascript
import { db } from './firebase-config.js';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';

await addDoc(collection(db, 'bookings'), {
  ...data,
  status: 'new',
  source: 'website',
  createdAt: serverTimestamp()
});
```

---

### Contact Form → `contactRequests` Collection

**Location**: `assets/js/contact.js` → `submitContact()` function

**Fields to save**:
```javascript
{
  name: string,
  email: string,
  phone: string,
  message: string,
  status: 'new',
  createdAt: serverTimestamp()
}
```

**Alternative**: Use Cloud Function to send email notification instead of writing to Firestore.

---

## Security & Anti-Spam

### Client-Side Measures (Implemented)

1. **Honeypot Field**: Hidden `<input name="website">` that bots fill but humans don't
2. **Rate Limiting**: 30-second cooldown using localStorage
3. **Validation**: All inputs validated before submission

### Production Recommendations (TODO)

1. **Server-Side Rate Limiting**:
   - Limit 5 submissions per IP per hour
   - Use Cloud Functions or API middleware

2. **reCAPTCHA v3** or **Cloudflare Turnstile**:
   - Add invisible CAPTCHA to forms
   - Validate score on backend

3. **Firestore Security Rules**:
   - **Never allow unrestricted client writes**
   - Use Cloud Functions to validate and write
   - Or require authentication for writes

Example security rule (restrictive):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{bookingId} {
      allow read: if request.auth != null;
      allow write: if false; // Only Cloud Functions can write
    }
  }
}
```

---

## Analytics Integration

Analytics hooks are included as console logs. Replace with actual tracking:

### Google Analytics / GTM

**Booking Submitted**:
```javascript
gtag('event', 'booking_submitted', {
  event_category: 'Lead Generation',
  event_label: data.typeOfWork,
  value: 1
});
```

**Contact Submitted**:
```javascript
gtag('event', 'contact_submitted', {
  event_category: 'Contact',
  event_label: 'Contact Form'
});
```

---

## Testing Checklist

### Book Consultation Page

- [ ] Form cannot submit with empty required fields
- [ ] Phone validation rejects invalid numbers (e.g., "123", "abc")
- [ ] Phone accepts valid formats: "9876543210", "+91 9876543210", "09876543210"
- [ ] District dropdown shows Kerala & Karnataka options
- [ ] typeOfWork dropdown shows all 12 service options
- [ ] Honeypot filled → form silently rejects (check console)
- [ ] After submit, success message appears with reference ID
- [ ] "Book another" button resets form
- [ ] Hero CTA button scrolls to form
- [ ] Query param `?service=turnkey-project` prefills typeOfWork
- [ ] FAQ accordion opens/closes correctly
- [ ] Tab order is logical (keyboard navigation)
- [ ] Error messages have `aria-live` announcements
- [ ] No console errors

### Contact Page

- [ ] Phone link (`tel:`) opens phone dialer
- [ ] Email link (`mailto:`) opens email client
- [ ] WhatsApp link (`wa.me`) opens WhatsApp
- [ ] Map link opens Google Maps
- [ ] Contact form validates required fields
- [ ] Success message appears after submit
- [ ] Success message auto-hides after 5 seconds
- [ ] Mobile layout is single-column
- [ ] Business hours table is readable
- [ ] No console errors

### About Page

- [ ] Page loads without errors
- [ ] All sections visible and styled correctly
- [ ] Stats row displays properly
- [ ] Values cards have hover effects
- [ ] Service areas section shows Kerala & Karnataka
- [ ] CTA buttons work (book consultation, phone, WhatsApp)
- [ ] Images load with lazy loading
- [ ] Responsive on mobile (single column)
- [ ] No console errors

---

## Browser Testing

Test on:
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (if available)
- [ ] Mobile Chrome (device mode or real device)
- [ ] Mobile Safari (if available)

---

## Accessibility Testing

- [ ] Run Lighthouse accessibility audit (target: 90+)
- [ ] Test with keyboard only (Tab, Enter, Escape, Arrow keys)
- [ ] Verify focus states are visible on all interactive elements
- [ ] Check color contrast ratios (WCAG AA minimum)
- [ ] Test with screen reader (NVDA, JAWS, or VoiceOver)
- [ ] Verify all images have alt text
- [ ] Ensure form labels are properly associated
- [ ] Check ARIA attributes are correct

---

## Customization Guide

### Replace Placeholders

Before deploying, replace these placeholders:

1. **Phone Numbers**: Search for `+91XXXXXXXXXX` and replace with actual number
2. **Email**: Replace `info@jsconstruction.com` with actual email
3. **WhatsApp**: Update `wa.me/91XXXXXXXXXX` with actual WhatsApp number
4. **Address**: Update office address in contact.html
5. **Stats**: Update numbers in about.html (years, projects, clients, team)
6. **Images**: Replace Unsplash URLs with actual company photos

### Customize Colors

Edit CSS variables in `assets/css/styles.css`:

```css
:root {
  --color-primary: #1e3a5f;    /* Deep blue */
  --color-accent: #e67e22;     /* Warm orange */
  /* ... other colors */
}
```

### Add More Form Fields

1. Add HTML input in form
2. Add validation rule in `booking.js` or `contact.js`
3. Update `collectFormData()` function
4. Update Firestore schema documentation

---

## Troubleshooting

### Form Not Submitting

- Check browser console for errors
- Verify all required fields are filled
- Check if honeypot field is visible (should be hidden)
- Clear localStorage and try again

### Validation Not Working

- Ensure `utils.js` is loaded before `booking.js` or `contact.js`
- Check that field IDs match JavaScript selectors
- Verify validation patterns are correct

### Styles Not Applied

- Check CSS file order in `<head>`
- Verify file paths are correct
- Clear browser cache
- Check for CSS syntax errors

---

## Next Steps

1. **Add Firebase Configuration**:
   - Create Firebase project
   - Add Firebase SDK to HTML
   - Implement Firestore writes in `booking.js` and `contact.js`

2. **Set Up Cloud Functions** (recommended):
   - Validate submissions server-side
   - Send email notifications
   - Write to Firestore with server timestamp

3. **Add Analytics**:
   - Set up Google Analytics or GTM
   - Replace console.log with actual tracking calls

4. **Enhance Security**:
   - Add reCAPTCHA
   - Implement server-side rate limiting
   - Set Firestore security rules

5. **Add Real Content**:
   - Replace placeholder images
   - Update phone numbers and email
   - Add actual company stats and team info

6. **SEO Optimization**:
   - Add JSON-LD structured data
   - Optimize meta descriptions
   - Add sitemap.xml

---

## Support

For questions or issues:
- Check browser console for error messages
- Review commented code for integration examples
- Refer to Firebase documentation for Firestore setup

---

**Last Updated**: 2026-01-25  
**Version**: 1.0
