/**
 * JS Brixen - Location Utilities
 * Using OpenStreetMap Nominatim for Reverse Geocoding (Free)
 */

export async function getCurrentLocation() {
    return new Promise((resolve, reject) => {
        if (!navigator.geolocation) {
            reject(new Error("Geolocation is not supported by your browser"));
            return;
        }

        navigator.geolocation.getCurrentPosition(
            async (position) => {
                try {
                    const lat = position.coords.latitude;
                    const lon = position.coords.longitude;

                    // Simple Reverse Geocoding using Nominatim
                    const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=10&addressdetails=1`);

                    if (!response.ok) {
                        throw new Error("Failed to fetch address details");
                    }

                    const data = await response.json();

                    // Construct result
                    const result = {
                        latitude: lat,
                        longitude: lon,
                        address: data.display_name,
                        // Try to extract useful parts
                        district: data.address.state_district || data.address.county || data.address.city || '',
                        state: data.address.state || '',
                        mapsLink: `https://www.google.com/maps?q=${lat},${lon}`
                    };

                    resolve(result);
                } catch (error) {
                    reject(error);
                }
            },
            (error) => {
                let msg = "Unable to retrieve your location";
                switch (error.code) {
                    case error.PERMISSION_DENIED:
                        msg = "User denied the request for Geolocation";
                        break;
                    case error.POSITION_UNAVAILABLE:
                        msg = "Location information is unavailable";
                        break;
                    case error.TIMEOUT:
                        msg = "The request to get user location timed out";
                        break;
                }
                reject(new Error(msg));
            }
        );
    });
}

