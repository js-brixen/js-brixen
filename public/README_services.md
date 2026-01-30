# Services Section - Documentation

This document explains how to preview, customize, and integrate the Services section with Firestore and Cloudinary.

---

## 📁 Files Created

```
public/
├── services.html                 # Services listing page
├── service-template.html         # Service detail template
├── README_services.md            # This file
└── assets/
    ├── css/
    │   └── services.css          # Services-specific styles
    └── js/
        └── services.js           # Services data & functionality
```

---

## 🚀 How to Preview Locally

### Option 1: Using npx http-server (Recommended)

```bash
npx http-server public -p 8080
```

Then open: `http://localhost:8080/services.html`

### Option 2: Using Python

```bash
# Python 3
cd public
python -m http.server 8080

# Python 2
cd public
python -m SimpleHTTPServer 8080
```

Then open: `http://localhost:8080/services.html`

### Option 3: Using VS Code Live Server

1. Install "Live Server" extension
2. Right-click on `public/services.html`
3. Select "Open with Live Server"

---

## 🎨 What's Included

### Services Listing Page (`services.html`)

**Features:**
- ✅ 11 service cards with real Unsplash images
- ✅ Search functionality (debounced, 300ms)
- ✅ Tag filtering (Turnkey, Renovation, Garden, etc.)
- ✅ Keyboard navigation (Arrow keys + Enter)
- ✅ Mobile sticky CTA button
- ✅ Fully accessible (ARIA labels, skip link, focus management)
- ✅ Responsive grid (1-4 columns based on screen size)

**The 11 Services:**
1. New House Construction
2. Renovation & Remodeling
3. Interior Design
4. Electrical & Plumbing
5. Waterproofing
6. Turnkey Project
7. Garden with Fruits
8. Outhouse with Muds
9. Open Fishtank
10. Pet House
11. Kerala Traditional House

### Service Detail Template (`service-template.html`)

**Features:**
- ✅ Dynamic hero section with breadcrumb
- ✅ "What We Provide" features list
- ✅ Process timeline (4-6 steps)
- ✅ Gallery with lightbox (click to enlarge, arrow navigation)
- ✅ FAQ accordion
- ✅ Related projects placeholder
- ✅ JSON-LD structured data for SEO
- ✅ Dynamic meta tags (title, description, Open Graph)

---

## 🔧 How It Works

### Data Flow

```
services.js (SERVICES array)
    ↓
services.html (renders cards dynamically)
    ↓
User clicks "View Details"
    ↓
service-template.html?service={slug}
    ↓
services.js (populates template with data)
```

### CTA Query String Format

When a user clicks "Book Consultation", they're redirected to:

```
/book-consultation.html?service={slug}&serviceTitle={encoded_title}
```

**Example:**
```
/book-consultation.html?service=new-house-construction&serviceTitle=New%20House%20Construction
```

**To read these parameters in `book-consultation.html`:**

```javascript
const params = new URLSearchParams(window.location.search);
const serviceSlug = params.get('service');      // "new-house-construction"
const serviceTitle = params.get('serviceTitle'); // "New House Construction"

// Pre-fill your form
document.getElementById('service-field').value = serviceTitle;
```

---

## 🖼️ Image Placeholders

Currently using **Unsplash** images as placeholders. These are production-ready and free to use.

### Current Image URLs

All images are referenced in `services.js` in the `SERVICES` array. Example:

```javascript
images: [
  "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80",
  "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=600&q=80"
]
```

### Replacing with Cloudinary

When you upload real images to Cloudinary, replace the URLs:

**Cloudinary URL format:**
```
https://res.cloudinary.com/YOUR_CLOUD_NAME/image/upload/v1/services/{slug}-1.jpg
```

**Example:**
```javascript
// Before (Unsplash)
images: [
  "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80"
]

// After (Cloudinary)
images: [
  "https://res.cloudinary.com/jsconstruction/image/upload/v1/services/new-house-construction-1.jpg",
  "https://res.cloudinary.com/jsconstruction/image/upload/v1/services/new-house-construction-2.jpg"
]
```

**Where to update:**
- Open `public/assets/js/services.js`
- Find the `SERVICES` array (starts around line 10)
- Update the `images` array for each service

---

## 🔥 Firestore Integration

### Current State: Static Data

Right now, all service data is stored in the `SERVICES` array in `services.js`.

### How to Wire to Firestore

#### 1. Create Firestore Collection

Create a collection called `services` with documents using the service `slug` as the document ID:

**Collection structure:**
```
services/
  ├── new-house-construction/
  │   ├── slug: "new-house-construction"
  │   ├── title: "New House Construction"
  │   ├── shortDescription: "..."
  │   ├── fullDescription: "..."
  │   ├── images: ["url1", "url2"]
  │   ├── tags: ["Turnkey", "Residential"]
  │   ├── features: [...]
  │   ├── process: [...]
  │   ├── faqs: [...]
  │   ├── seo: {...}
  │   └── areaServed: ["Kerala", "Karnataka"]
  ├── renovation-remodeling/
  └── ...
```

#### 2. Update `services.js`

**Find this section** (around line 500):

```javascript
// ========== SERVICES LISTING ==========
function initServicesListing() {
  renderCards(SERVICES);
  setupSearch();
  setupTagFilters();
  setupKeyboardNav();
  setupCTAAnalytics();
}
```

**Replace with:**

```javascript
// ========== SERVICES LISTING ==========
async function initServicesListing() {
  // ===== FIRESTORE INTEGRATION =====
  const db = firebase.firestore();
  const snapshot = await db.collection('services').get();
  const services = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  
  renderCards(services);
  setupSearch();
  setupTagFilters();
  setupKeyboardNav();
  setupCTAAnalytics();
}
```

**And find this section** (around line 700):

```javascript
// ========== SERVICE DETAIL PAGE ==========
function initServiceDetail() {
  const params = new URLSearchParams(window.location.search);
  const serviceSlug = params.get('service');
  
  if (!serviceSlug) {
    window.location.href = '/services.html';
    return;
  }

  const serviceData = SERVICES.find(s => s.slug === serviceSlug);
  
  if (!serviceData) {
    window.location.href = '/services.html';
    return;
  }

  populateServicePage(serviceData);
}
```

**Replace with:**

```javascript
// ========== SERVICE DETAIL PAGE ==========
async function initServiceDetail() {
  const params = new URLSearchParams(window.location.search);
  const serviceSlug = params.get('service');
  
  if (!serviceSlug) {
    window.location.href = '/services.html';
    return;
  }

  // ===== FIRESTORE INTEGRATION =====
  const db = firebase.firestore();
  const doc = await db.collection('services').doc(serviceSlug).get();
  
  if (!doc.exists) {
    window.location.href = '/services.html';
    return;
  }

  const serviceData = { id: doc.id, ...doc.data() };
  populateServicePage(serviceData);
}
```

#### 3. Add Firebase SDK

Add these scripts to `services.html` and `service-template.html` **before** `services.js`:

```html
<!-- Firebase SDK -->
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-firestore-compat.js"></script>

<!-- Initialize Firebase -->
<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    // ... other config
  };
  firebase.initializeApp(firebaseConfig);
</script>

<!-- Then load services.js -->
<script src="assets/js/services.js"></script>
```

---

## ✅ Testing Checklist

Before deploying, verify:

### Responsive Design
- [ ] Page looks good on mobile (320px width)
- [ ] Page looks good on tablet (768px width)
- [ ] Page looks good on desktop (1024px width)
- [ ] Page looks good on wide screens (1440px+ width)
- [ ] No horizontal scrolling on any breakpoint

### Functionality
- [ ] Search works (type "renovation" → only renovation services show)
- [ ] Tag filters work (click "Garden" → only garden services show)
- [ ] "All" tag shows all services
- [ ] Results count updates correctly
- [ ] Cards are keyboard navigable (Tab, Arrow keys)
- [ ] Pressing Enter on a card opens detail page

### Service Detail Page
- [ ] Clicking "View Details" opens correct service
- [ ] All sections populate with correct data
- [ ] Gallery images open in lightbox
- [ ] Lightbox navigation works (←/→ arrows)
- [ ] Lightbox closes on Esc or X button
- [ ] FAQ accordion expands/collapses
- [ ] Breadcrumb shows correct service name

### CTAs
- [ ] "Book Consultation" includes correct query params
- [ ] Query string format: `?service={slug}&serviceTitle={title}`
- [ ] Mobile sticky CTA appears on mobile only

### Accessibility
- [ ] Skip link appears on Tab and works
- [ ] All images have alt text
- [ ] All buttons are keyboard accessible
- [ ] Focus is visible on all interactive elements
- [ ] Screen reader announces results count changes
- [ ] Lightbox traps focus when open

### Performance
- [ ] No console errors on page load
- [ ] Images load with lazy loading
- [ ] Page loads quickly (< 3 seconds)

---

## 🎨 Customization

### Changing Colors

Edit `public/assets/css/services.css`:

```css
:root {
  /* Tag Colors */
  --tag-turnkey: #2ecc71;      /* Change to your brand color */
  --tag-renovation: #3498db;
  /* ... etc */
}
```

### Adding/Removing Services

Edit `public/assets/js/services.js`:

1. Find the `SERVICES` array (starts around line 10)
2. Add/remove service objects
3. Each service must have all required fields:
   - `slug`, `title`, `shortDescription`, `fullDescription`
   - `images`, `tags`, `features`, `process`, `faqs`
   - `seo`, `areaServed`

### Changing Animation Speed

Edit `public/assets/css/services.css`:

```css
:root {
  --transition-fast: 150ms;    /* Change these values */
  --transition-medium: 300ms;
  --transition-slow: 500ms;
}
```

---

## 🐛 Troubleshooting

### Cards not showing?

1. Check browser console for errors
2. Verify `services.js` is loaded (check Network tab)
3. Verify `SERVICES` array is not empty

### Search not working?

1. Ensure input has `id="service-search"`
2. Check console for JavaScript errors
3. Try clearing browser cache

### Lightbox not opening?

1. Verify gallery items have class `gallery-item`
2. Check that lightbox modal exists in HTML
3. Ensure `services.js` is loaded after DOM

### Service detail page shows "Loading..."?

1. Check URL has `?service={slug}` parameter
2. Verify slug exists in SERVICES array
3. Check browser console for errors

---

## 📞 Support

For questions or issues:
- Review the code comments in `services.js` and `services.css`
- Check browser console for error messages
- Verify all files are in correct locations

---

## 🚀 Next Steps

1. **Preview locally** using one of the methods above
2. **Test all functionality** using the checklist
3. **Replace images** with your Cloudinary URLs
4. **Integrate Firestore** when ready
5. **Deploy** to your hosting platform

---

**Built with ❤️ for JS Construction**
