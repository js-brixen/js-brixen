# JS Construction Static Website

A modern, responsive static website for JS Construction featuring 6 pages with a clean construction-business design.

## 📁 Project Structure

```
/public/
├── index.html                       # Home page with complete hero section
├── services.html                    # Services listing page
├── projects.html                    # Portfolio/projects page
├── book-consultation.html           # Booking consultation page
├── about.html                       # About Us page
├── contact.html                     # Contact page
└── assets/
    ├── css/
    │   └── styles.css               # Single stylesheet with CSS variables
    ├── js/
    │   └── main.js                  # Mobile nav, smooth scroll, sticky header
    └── img/
        └── (placeholder images)
```

## 🚀 Preview Locally

### Option 1: Direct Open (Simple)
Simply open `public/index.html` in your web browser.

### Option 2: Local Server (Recommended)
For better testing of navigation and features:

```bash
# Using http-server (install if needed)
npx http-server public -p 8080
```

Then visit: **http://localhost:8080**

### Option 3: Live Server (VS Code)
If you're using VS Code:
1. Install the "Live Server" extension
2. Right-click on `public/index.html`
3. Select "Open with Live Server"

## 🎨 Customization Guide

### Brand Colors
Edit `assets/css/styles.css` at the top:

```css
:root {
  --color-primary: #1e3a5f;  /* Deep blue - main brand color */
  --color-accent: #e67e22;   /* Warm orange - CTA buttons */
  --color-bg: #f8f9fa;       /* Light gray background */
}
```

### Hero Section Text
Edit `index.html` around lines 50-60:

- **Headline**: `<h1>Build Your Dream Home in Kerala & Karnataka</h1>`
- **Subtext**: `<p class="hero__subtext">Turnkey construction, renovations...</p>`
- **CTA Button**: `<a href="book-consultation.html#booking-form" class="btn-primary">Book Free Consultation</a>`

### Hero Image
Replace the Unsplash URL in `index.html`:

```html
<img src="https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=1200&q=80" 
     alt="Construction professional reviewing blueprints on site">
```

Or add your own image to `assets/img/` and update the `src` attribute.

### Contact Information
Replace placeholder contact details in all pages:

- **Phone**: `+91XXXXXXXXXX` → Your actual phone number
- **Email**: `info@jsconstruction.com` → Your actual email
- **WhatsApp**: Update the `wa.me/91XXXXXXXXXX` link
- **Address**: Update in `contact.html`

### Navigation Links
All pages use the same header navigation. To add/remove links, edit the `<nav>` section in each HTML file.

## 📝 Content Placeholders

The following sections are intentionally left as placeholders for you to customize:

### Services Page (`services.html`)
- 6 service cards with emoji icons
- Replace titles, descriptions, and add real images

### Projects Page (`projects.html`)
- Gallery grid with placeholder tiles
- Add actual project images from Cloudinary or local storage

### Book Consultation Page (`book-consultation.html`)
- Contains `#booking-form` anchor (target for CTA button)
- Replace placeholder with actual booking form (Firebase integration ready)

### About Page (`about.html`)
- Mission statement
- Company values
- Team/experience section

### Contact Page (`contact.html`)
- Contact details
- Service areas
- Office address

## 🔧 Features

### Responsive Design
- Mobile-first approach
- Breakpoints: 768px (tablet), 1024px (desktop)
- Hamburger menu on mobile devices

### JavaScript Functionality
- **Mobile Navigation**: Hamburger toggle with smooth slide-in
- **Sticky Header**: Shadow appears when scrolling down
- **Smooth Scroll**: Anchor links scroll smoothly to target sections
- **Accessibility**: ARIA attributes, keyboard navigation support

### SEO Optimized
- Semantic HTML5 structure
- Meta descriptions on all pages
- Open Graph tags for social sharing
- Alt attributes on images

## 🔗 CTA Flow

The main call-to-action flow:
1. User clicks "Book Free Consultation" on Home page
2. Navigates to `book-consultation.html#booking-form`
3. Smooth scrolls to the booking form section

## 🚧 Future Integration

This skeleton is designed for easy integration with:

### Firebase
Add Firebase SDK scripts to `<head>` in HTML files:
```html
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.x.x/firebase-firestore.js"></script>
```

Initialize in `main.js` or create a separate `firebase-config.js`.

### Cloudinary
Replace Unsplash URLs with Cloudinary delivery URLs:
```html
<img src="https://res.cloudinary.com/YOUR_CLOUD_NAME/image/upload/v1234567890/sample.jpg">
```

### Booking Form
Replace the placeholder in `book-consultation.html` with a form that submits to Firestore:
- Name, Phone, Email fields
- Project type dropdown
- Preferred date/time picker
- Location/address input

## 📱 Browser Compatibility

Tested and works on:
- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## 🎯 Accessibility

- Semantic HTML structure
- ARIA labels on interactive elements
- Keyboard navigation support
- Focus visible on all interactive elements
- Alt text on images

## 📄 License

© 2026 JS Construction. All rights reserved.

---

**Need Help?** 
- Check the HTML comments in each file for guidance
- CSS is organized with clear sections and comments
- JavaScript functions are well-documented
