# Projects / Portfolio Section - Documentation

> **Quick Start**: Open `http://localhost:8080/projects.html` in your browser to see the projects listing page. Click any project card to view the detail page.

---

## Table of Contents

1. [File Structure](#file-structure)
2. [Quick Start](#quick-start)
3. [Data Structure](#data-structure)
4. [Firestore Integration](#firestore-integration)
5. [Cloudinary Integration](#cloudinary-integration)
6. [View Count Implementation](#view-count-implementation)
7. [Testing Checklist](#testing-checklist)
8. [Accessibility Notes](#accessibility-notes)

---

## File Structure

```
/public/
├── projects.html                    # Projects listing page
├── project-template.html            # Project detail page template
├── assets/
│   ├── css/
│   │   └── projects.css            # All project styles
│   └── js/
│       └── projects.js             # All project logic
└── snippets/
    └── project-card.html           # Card HTML fragment (optional)
```

### What Each File Does

| File | Purpose |
|------|---------|
| `projects.html` | Main listing page with filters, search, and grid |
| `project-template.html` | Detail page template (loads via `?project=<slug>`) |
| `projects.css` | Responsive styles, grid, carousel, lightbox |
| `projects.js` | Data, rendering, filtering, pagination, analytics |

---

## Quick Start

### 1. Preview Locally

The site is already running on `http://localhost:8080` (you have http-server running).

```bash
# If not running, start the server:
npx http-server public -p 8080
```

### 2. View Pages

- **Listing**: `http://localhost:8080/projects.html`
- **Detail**: `http://localhost:8080/project-template.html?project=lakeside-modern-villa`

### 3. Test Features

- Use the search box to filter by name/location
- Click category chips to filter by type
- Change the sort dropdown
- Click "Load More" to paginate
- Click a project card to view details
- Navigate the hero carousel
- Click gallery images to open lightbox
- Test keyboard navigation (arrows, Enter, Escape)

---

## Data Structure

### PROJECTS Array Schema

Each project in the `PROJECTS` array (in `projects.js`) has this structure:

```javascript
{
  slug: "lakeside-modern-villa",          // Unique identifier (URL-safe)
  title: "Lakeside Modern Villa",         // Display name
  district: "Kochi, Kerala",              // Location
  type: "new",                            // "new" | "renovation" | "interior"
  summary: "One-line description...",     // Short description (2 lines max)
  description: "Full description...",     // Multi-paragraph description
  images: [                               // Array of image objects
    {
      url: "https://...",                 // Image URL (Cloudinary secure_url)
      alt: "Descriptive alt text"         // Accessibility text
    }
  ],
  isFeatured: true,                       // Boolean (shows first when sorting by featured)
  tags: ["modern", "lakefront", "3bhk"],  // Array of tags for search/filter
  views: 342,                             // Number (for sorting by popularity)
  createdAt: new Date("2025-09-15"),      // Date object (for sorting by newest)
  meta: {                                 // Additional metadata
    area: "3200 sq ft",                   // Project size
    duration: "14 months",                // Construction duration
    year: 2025,                           // Completion year
    services: [                           // Services provided
      "New House Construction",
      "Interior Design",
      "Landscaping"
    ]
  }
}
```

### Adding a New Project

1. Open `public/assets/js/projects.js`
2. Add a new object to the `PROJECTS` array
3. Follow the schema above
4. Use Cloudinary URLs for images (see [Cloudinary Integration](#cloudinary-integration))

---

## Firestore Integration

### Collection Structure

**Firestore Path**: `projects/{slug}`

Each document should have the same fields as the PROJECTS array schema above.

### Example Firestore Document

```javascript
// Document ID: lakeside-modern-villa
{
  slug: "lakeside-modern-villa",
  title: "Lakeside Modern Villa",
  district: "Kochi, Kerala",
  type: "new",
  summary: "Contemporary 4BHK villa...",
  description: "This stunning lakeside villa...",
  images: [
    {
      url: "https://res.cloudinary.com/your-cloud/image/upload/v1234/project1.jpg",
      alt: "Lakeside villa exterior"
    }
  ],
  isFeatured: true,
  tags: ["modern", "lakefront", "4bhk"],
  views: 342,
  createdAt: firebase.firestore.Timestamp.fromDate(new Date("2025-09-15")),
  meta: {
    area: "3200 sq ft",
    duration: "14 months",
    year: 2025,
    services: ["New House Construction", "Interior Design"]
  }
}
```

### Replace Static Data with Firestore

**In `projects.js`, replace the PROJECTS array initialization:**

```javascript
// BEFORE (static data)
const PROJECTS = [ /* ... */ ];

// AFTER (Firestore fetch)
let PROJECTS = [];

async function fetchProjects() {
  const db = firebase.firestore();
  const snapshot = await db.collection('projects')
    .orderBy('createdAt', 'desc')
    .get();

  PROJECTS = snapshot.docs.map(doc => {
    const data = doc.data();
    return {
      ...data,
      createdAt: data.createdAt.toDate() // Convert Firestore Timestamp to Date
    };
  });

  // Initialize after data is loaded
  initProjectsListing();
}

// Call on page load
document.addEventListener('DOMContentLoaded', () => {
  const isListingPage = document.getElementById('projects-grid') !== null;
  if (isListingPage) {
    fetchProjects();
  }
});
```

**For the detail page:**

```javascript
async function initProjectDetail() {
  const params = new URLSearchParams(window.location.search);
  const slug = params.get('project');

  if (!slug) {
    window.location.href = 'projects.html';
    return;
  }

  const db = firebase.firestore();
  const doc = await db.collection('projects').doc(slug).get();

  if (!doc.exists) {
    window.location.href = 'projects.html';
    return;
  }

  const project = {
    ...doc.data(),
    createdAt: doc.data().createdAt.toDate()
  };

  populateProjectDetail(project);
}
```

---

## Cloudinary Integration

### Upload Process (Admin App)

1. User uploads image via Admin App
2. Admin App sends image to Cloudinary (signed upload)
3. Cloudinary returns `secure_url`
4. Admin App stores `secure_url` in Firestore `projects/{slug}.images[]`

### URL Transformation Patterns

Cloudinary allows on-the-fly image transformations via URL parameters.

| Context | Transformation | Example URL |
|---------|---------------|-------------|
| **Card Cover** | `c_fill,w_600,h_450,q_auto,f_auto` | `https://res.cloudinary.com/.../c_fill,w_600,h_450,q_auto,f_auto/image.jpg` |
| **Hero Carousel** | `c_fill,w_1600,h_900,q_auto,f_auto` | `https://res.cloudinary.com/.../c_fill,w_1600,h_900,q_auto,f_auto/image.jpg` |
| **Gallery Thumb** | `c_fill,w_400,h_300,q_auto,f_auto` | `https://res.cloudinary.com/.../c_fill,w_400,h_300,q_auto,f_auto/image.jpg` |
| **Lightbox** | `w_1920,q_auto,f_auto` | `https://res.cloudinary.com/.../w_1920,q_auto,f_auto/image.jpg` |

### Applying Transformations in Code

**Option 1: Store base URL, transform in code**

```javascript
function getTransformedURL(baseURL, transformation) {
  // Insert transformation before the version number
  // Example: https://res.cloudinary.com/demo/image/upload/v1234/sample.jpg
  // Becomes: https://res.cloudinary.com/demo/image/upload/c_fill,w_600/v1234/sample.jpg
  return baseURL.replace('/upload/', `/upload/${transformation}/`);
}

// Usage
const cardImage = getTransformedURL(project.images[0].url, 'c_fill,w_600,h_450,q_auto,f_auto');
```

**Option 2: Store multiple sizes in Firestore**

```javascript
images: [
  {
    original: "https://res.cloudinary.com/.../image.jpg",
    card: "https://res.cloudinary.com/.../c_fill,w_600,h_450,q_auto,f_auto/image.jpg",
    hero: "https://res.cloudinary.com/.../c_fill,w_1600,h_900,q_auto,f_auto/image.jpg",
    alt: "Description"
  }
]
```

---

## View Count Implementation

### ⚠️ Why NOT to Increment Views Client-Side

**Problem**: Direct Firestore writes from the client can be easily abused:
- Users can refresh the page repeatedly to inflate views
- No rate limiting
- Difficult to detect bots

**Solution**: Use a Cloud Function with server-side logic.

### Cloud Function Approach

**1. Create Cloud Function** (`functions/index.js`):

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.incrementProjectViews = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');

  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    return res.status(204).send('');
  }

  const slug = req.query.slug || req.body.slug;

  if (!slug) {
    return res.status(400).json({ error: 'Missing slug parameter' });
  }

  try {
    const projectRef = admin.firestore().collection('projects').doc(slug);
    const doc = await projectRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Increment view count
    await projectRef.update({
      views: admin.firestore.FieldValue.increment(1)
    });

    res.json({ success: true, slug });
  } catch (error) {
    console.error('Error incrementing views:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**2. Call from Client** (in `projects.js`):

```javascript
async function incrementProjectViews(slug) {
  try {
    await fetch(`https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/incrementProjectViews?slug=${slug}`, {
      method: 'POST'
    });
  } catch (error) {
    console.error('Failed to increment views:', error);
  }
}

// Call when project detail page loads
function initProjectDetail() {
  // ... existing code ...

  incrementProjectViews(project.slug);
}
```

**3. Add Rate Limiting** (optional but recommended):

Use Firestore to track IP addresses and timestamps to prevent abuse:

```javascript
// In Cloud Function
const viewsRef = admin.firestore().collection('projectViews');
const ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
const viewKey = `${slug}_${ip}`;
const now = admin.firestore.Timestamp.now();

const viewDoc = await viewsRef.doc(viewKey).get();

if (viewDoc.exists) {
  const lastView = viewDoc.data().timestamp.toDate();
  const hoursSinceLastView = (now.toDate() - lastView) / 1000 / 60 / 60;

  if (hoursSinceLastView < 24) {
    // Don't count view if same IP viewed within 24 hours
    return res.json({ success: true, counted: false });
  }
}

// Record this view
await viewsRef.doc(viewKey).set({ timestamp: now });

// Increment counter
await projectRef.update({ views: admin.firestore.FieldValue.increment(1) });
```

---

## Testing Checklist

### Responsive Design
- [ ] Grid shows 1 column at 320px width
- [ ] Grid shows 2 columns at 768px width
- [ ] Grid shows 3 columns at 1024px width
- [ ] Mobile sticky CTA appears on screens < 1024px
- [ ] Desktop sidebar CTA is sticky on screens >= 1024px

### Filtering & Search
- [ ] Search box filters by project title
- [ ] Search box filters by district
- [ ] Search box filters by summary text
- [ ] Search box filters by tags
- [ ] Category chips filter correctly (New/Renovation/Interior)
- [ ] Multiple category chips can be selected
- [ ] "All Projects" chip clears other filters
- [ ] Results count updates correctly

### Sorting
- [ ] "Featured First" shows featured projects first
- [ ] "Newest First" sorts by createdAt date
- [ ] "Most Viewed" sorts by views count

### Pagination
- [ ] Initial load shows 9 projects
- [ ] "Load More" button appears if more than 9 projects
- [ ] "Load More" reveals 6 additional projects
- [ ] "Load More" button hides when all projects shown
- [ ] Results count updates after loading more

### Keyboard Navigation
- [ ] Arrow keys navigate between project cards
- [ ] Enter key opens project detail page
- [ ] Escape key closes lightbox modal
- [ ] Tab key navigates through interactive elements
- [ ] Focus ring is visible on all interactive elements

### Project Detail Page
- [ ] Opens with `?project=<slug>` query parameter
- [ ] Redirects to listing if no slug provided
- [ ] Redirects to listing if slug not found
- [ ] Page title updates to project title
- [ ] Meta description updates to project summary
- [ ] JSON-LD structured data populates correctly

### Hero Carousel
- [ ] First image loads immediately (eager loading)
- [ ] Other images lazy load
- [ ] Left/right buttons navigate images
- [ ] Dots indicate current slide
- [ ] Clicking dot navigates to that slide
- [ ] Touch swipe works on mobile
- [ ] Carousel wraps around (last → first, first → last)

### Gallery & Lightbox
- [ ] Gallery grid displays all project images
- [ ] Clicking thumbnail opens lightbox
- [ ] Lightbox shows full-size image
- [ ] Left/right buttons navigate images
- [ ] Arrow keys navigate images
- [ ] Escape key closes lightbox
- [ ] Touch swipe works on mobile
- [ ] Image counter shows current position (e.g., "3 / 12")
- [ ] Caption displays image alt text
- [ ] Focus returns to gallery item on close

### CTAs & Links
- [ ] "Book Consultation" includes `relatedProjectId` query param
- [ ] "Book Consultation" includes `relatedProjectTitle` query param
- [ ] Query params are properly URL-encoded
- [ ] Social share buttons work correctly
- [ ] "Copy Link" button copies current URL
- [ ] WhatsApp/Twitter/Facebook links open in new tab

### Accessibility
- [ ] Skip link appears on focus
- [ ] All images have alt text
- [ ] All interactive elements are keyboard-focusable
- [ ] ARIA attributes are present and correct
- [ ] Color contrast meets WCAG AA standards
- [ ] Focus trap works in lightbox
- [ ] Screen reader announcements work (aria-live)

### Performance
- [ ] Images use `loading="lazy"` attribute
- [ ] Hero carousel first image uses `loading="eager"`
- [ ] No JavaScript console errors
- [ ] Page loads in < 3 seconds on 3G
- [ ] Lighthouse Performance score > 80
- [ ] Lighthouse Accessibility score > 90

---

## Accessibility Notes

### WCAG AA Compliance

This projects module is designed to meet WCAG 2.1 Level AA standards:

| Criterion | Implementation |
|-----------|----------------|
| **1.1.1 Non-text Content** | All images have descriptive alt text from `project.images[].alt` |
| **1.3.1 Info and Relationships** | Semantic HTML (`<main>`, `<article>`, `<nav>`, `<dl>`, etc.) |
| **1.4.3 Contrast** | All text meets 4.5:1 contrast ratio; badges meet 3:1 |
| **2.1.1 Keyboard** | All functionality available via keyboard |
| **2.4.1 Bypass Blocks** | Skip link to main content |
| **2.4.2 Page Titled** | Dynamic page titles for each project |
| **2.4.7 Focus Visible** | Focus ring visible on all interactive elements |
| **3.2.4 Consistent Identification** | Consistent button/link labels across pages |
| **4.1.2 Name, Role, Value** | ARIA attributes on custom controls |
| **4.1.3 Status Messages** | `aria-live` on results count and lightbox counter |

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Tab** | Navigate forward through interactive elements |
| **Shift+Tab** | Navigate backward through interactive elements |
| **Arrow Keys** | Navigate between project cards (on listing page) |
| **Enter** | Open project detail / Activate button |
| **Escape** | Close lightbox modal |
| **Left/Right Arrows** | Navigate carousel/lightbox images |

### Screen Reader Support

- Results count announces changes via `aria-live="polite"`
- Lightbox counter announces image position via `aria-live="polite"`
- All buttons have descriptive `aria-label` attributes
- Form inputs have associated `<label>` elements

---

## Troubleshooting

### Images Not Loading

**Problem**: Images show broken image icon.

**Solution**:
1. Check browser console for CORS errors
2. Verify Cloudinary URLs are correct
3. Ensure Cloudinary account is active
4. Check network tab for 404 errors

### Filters Not Working

**Problem**: Clicking filter chips doesn't filter projects.

**Solution**:
1. Check browser console for JavaScript errors
2. Verify `projects.js` is loaded after `main.js`
3. Ensure `data-type` attributes match project types

### Lightbox Not Opening

**Problem**: Clicking gallery images doesn't open lightbox.

**Solution**:
1. Verify lightbox HTML is present in page
2. Check that `setupLightbox()` is called
3. Ensure gallery items have `data-index` attributes

### Query Params Not Working

**Problem**: Project detail page doesn't load correct project.

**Solution**:
1. Check URL has `?project=<slug>` parameter
2. Verify slug matches a project in PROJECTS array
3. Check browser console for redirect messages

---

## Next Steps

1. **Test Locally**: Run through the [Testing Checklist](#testing-checklist)
2. **Add Real Images**: Replace Unsplash placeholders with actual project photos
3. **Integrate Firestore**: Follow [Firestore Integration](#firestore-integration) guide
4. **Set Up Cloudinary**: Configure image uploads in Admin App
5. **Deploy**: Push to production and test live

---

## Support

For questions or issues:
- Check browser console for error messages
- Review this documentation
- Refer to `projects.js` comments for code examples
- Test with sample project: `?project=lakeside-modern-villa`
