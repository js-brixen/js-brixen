/**
 * JS Brixen - Customer Authentication Modal
 * 
 * Handles the UI for customer authentication modal.
 * Works with customer-auth.js for authentication logic.
 */

(function () {
    'use strict';

    let modal, backdrop, closeBtn;
    let step1, stepSignUp, stepGooglePassword, step2, loggedInStep;
    let googleSignInBtn, emailSignInForm, emailSignUpForm;
    let emailSignInBtn, emailSignUpBtn, googlePasswordNextBtn;
    let switchToSignUpBtn, switchToSignInBtn;
    let completeSignupBtn, continueBtn, signOutBtn;
    let phoneInput, googleSignUpPassword, userPhoto, userName;
    let onAuthenticatedCallback, onCancelCallback;

    // Store temporary google user during sign up flow
    let temporaryGoogleUser = null;

    /**
     * Initialize auth modal
     */
    function init() {
        modal = $('#authModal');
        if (!modal) {
            console.warn('Auth modal not found in DOM');
            return;
        }

        backdrop = modal.querySelector('.auth-modal__backdrop');
        closeBtn = modal.querySelector('.auth-modal__close');

        step1 = $('#authStep1'); // Sign In Step
        stepSignUp = $('#authStepSignUp'); // Sign Up Step
        stepGooglePassword = $('#authStepGooglePassword'); // Google Password Step
        step2 = $('#authStep2'); // Phone Step
        loggedInStep = $('#authLoggedIn');

        googleSignInBtn = $('#googleSignInBtn');
        emailSignInForm = $('#emailSignInForm');
        emailSignUpForm = $('#emailSignUpForm');

        emailSignInBtn = $('#emailSignInBtn');
        emailSignUpBtn = $('#emailSignUpBtn');

        switchToSignUpBtn = $('#switchToSignUp');
        switchToSignInBtn = $('#switchToSignIn');

        completeSignupBtn = $('#completeSignupBtn');
        googlePasswordNextBtn = $('#googlePasswordNextBtn');
        continueBtn = $('#continueBtn');
        signOutBtn = $('#signOutBtn');

        phoneInput = $('#customerPhone');
        googleSignUpPassword = $('#googleSignUpPassword');
        userPhoto = $('#userPhoto');
        userName = $('#userName');

        // Event listeners
        if (closeBtn) closeBtn.addEventListener('click', handleClose);
        if (backdrop) backdrop.addEventListener('click', handleClose);

        // Select all Google Sign-In buttons (both sign-in and sign-up steps)
        const googleSignInButtons = step1?.querySelectorAll('.btn-google') || [];
        googleSignInButtons.forEach(btn => {
            btn.addEventListener('click', handleGoogleSignIn);
        });

        const googleSignUpButtons = stepSignUp?.querySelectorAll('.btn-google') || [];
        googleSignUpButtons.forEach(btn => {
            btn.addEventListener('click', handleGoogleSignUp);
        });

        if (emailSignInForm) emailSignInForm.addEventListener('submit', handleEmailSignIn);
        if (emailSignUpForm) emailSignUpForm.addEventListener('submit', handleEmailSignUp);

        if (switchToSignUpBtn) switchToSignUpBtn.addEventListener('click', (e) => {
            e.preventDefault();
            showStepSignUp();
        });

        if (switchToSignInBtn) switchToSignInBtn.addEventListener('click', (e) => {
            e.preventDefault();
            showStep1();
        });

        if (completeSignupBtn) completeSignupBtn.addEventListener('click', handleCompleteSignup);
        if (googlePasswordNextBtn) googlePasswordNextBtn.addEventListener('click', handleGooglePasswordNext);
        if (continueBtn) continueBtn.addEventListener('click', handleContinue);
        if (signOutBtn) signOutBtn.addEventListener('click', handleSignOut);

        // Phone input validation
        if (phoneInput) {
            phoneInput.addEventListener('input', (e) => {
                e.target.value = e.target.value.replace(/\D/g, '').slice(0, 10);
            });
        }

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && modal.style.display !== 'none') {
                handleClose();
            }
        });

        // Check if already logged in on page load
        checkAuthState();

        console.log('Auth modal initialized');
    }

    /**
     * Check current auth state
     */
    async function checkAuthState() {
        if (window.CustomerAuth) {
            await window.CustomerAuth.onAuthStateChange((customer) => {
                if (customer) {
                    console.log('Customer already logged in:', customer);
                }
            });
        }
    }

    /**
     * Show auth modal
     * @param {Function} onAuthenticated - Called when user completes auth
     * @param {Function} onCancel - Called when user cancels
     */
    function show(onAuthenticated, onCancel) {
        if (!modal) return;

        onAuthenticatedCallback = onAuthenticated;
        onCancelCallback = onCancel;

        // Check if already logged in
        if (window.CustomerAuth && window.CustomerAuth.isLoggedIn()) {
            showLoggedInState(window.CustomerAuth.getCurrentCustomer());
        } else {
            showStep1();
        }

        modal.style.display = 'block';
        document.body.style.overflow = 'hidden'; // Prevent background scroll

        // Accessibility
        modal.setAttribute('aria-hidden', 'false');
        googleSignInBtn?.focus();
    }

    /**
     * Hide auth modal
     */
    function hide() {
        if (!modal) return;

        modal.style.display = 'none';
        document.body.style.overflow = '';
        modal.setAttribute('aria-hidden', 'true');

        // Reset to step 1
        showStep1();

        // Reset forms
        if (emailSignInForm) emailSignInForm.reset();
        if (emailSignUpForm) emailSignUpForm.reset();
    }

    /**
     * Show step 1 (Sign In Options)
     */
    function showStep1() {
        if (step1) step1.style.display = 'block';
        if (stepSignUp) stepSignUp.style.display = 'none';
        if (step2) step2.style.display = 'none';
        if (loggedInStep) loggedInStep.style.display = 'none';

        // Update header text
        const title = modal.querySelector('h2');
        if (title) title.textContent = 'Sign In to Continue';

        // Update subtitle
        const subtitle = modal.querySelector('p');
        if (subtitle && !subtitle.classList.contains('auth-switch-text')) subtitle.textContent = 'Please sign in to access your account';
    }

    /**
     * Show Sign Up Step
     */
    function showStepSignUp() {
        if (step1) step1.style.display = 'none';
        if (stepSignUp) stepSignUp.style.display = 'block';
        if (step2) step2.style.display = 'none';
        if (loggedInStep) loggedInStep.style.display = 'none';

        // Update header text
        const title = modal.querySelector('h2');
        if (title) title.textContent = 'Create Account';

        // Update subtitle
        const subtitle = modal.querySelector('p');
        if (subtitle && !subtitle.classList.contains('auth-switch-text')) subtitle.textContent = 'Join us to book consultations and track projects';
    }

    /**
     * Show step Google Password
     */
    function showStepGooglePassword() {
        if (step1) step1.style.display = 'none';
        if (stepSignUp) stepSignUp.style.display = 'none';
        if (stepGooglePassword) stepGooglePassword.style.display = 'block';
        if (step2) step2.style.display = 'none';
        if (loggedInStep) loggedInStep.style.display = 'none';

        if (googleSignUpPassword) {
            googleSignUpPassword.value = ''; // clear previous
            googleSignUpPassword.focus();
        }

        // Update header text
        const title = modal.querySelector('h2');
        if (title) title.textContent = 'Create Password';
    }

    /**
     * Show step 2 (Phone input for new users)
     */
    function showStep2() {
        if (step1) step1.style.display = 'none';
        if (stepSignUp) stepSignUp.style.display = 'none';
        if (stepGooglePassword) stepGooglePassword.style.display = 'none';
        if (step2) step2.style.display = 'block';
        if (loggedInStep) loggedInStep.style.display = 'none';
        if (phoneInput) phoneInput.focus();

        // Update header text
        const title = modal.querySelector('h2');
        if (title) title.textContent = 'Complete Your Profile';
    }

    /**
     * Show logged in state
     * @param {Object} customer - Customer data
     */
    function showLoggedInState(customer) {
        if (step1) step1.style.display = 'none';
        if (stepSignUp) stepSignUp.style.display = 'none';
        if (step2) step2.style.display = 'none';
        if (loggedInStep) loggedInStep.style.display = 'block';

        if (userPhoto && customer.photoURL) {
            userPhoto.src = customer.photoURL;
            userPhoto.alt = customer.displayName || 'User';
        } else if (userPhoto) {
            // Fallback if no photo
            userPhoto.src = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(customer.displayName || customer.email) + '&background=E67E22&color=fff';
        }

        if (userName) {
            userName.textContent = customer.displayName || customer.email;
        }

        const title = modal.querySelector('h2');
        if (title) title.textContent = 'Welcome Back';
    }

    /**
     * Handle Email Sign-In
     */
    async function handleEmailSignIn(e) {
        e.preventDefault();

        const email = $('#signInEmail').value;
        const password = $('#signInPassword').value;

        if (!email || !password) {
            showToast('Please enter both email and password', 'error');
            return;
        }

        setLoading(emailSignInBtn, true);

        try {
            // First, check if the email exists
            const emailExists = await window.CustomerAuth.checkIfEmailExists(email);

            if (!emailExists) {
                showToast('No account found. Redirecting to sign up...', 'warning');
                setTimeout(() => {
                    showStepSignUp();
                }, 1500);
                setLoading(emailSignInBtn, false);
                return;
            }

            // Email exists, proceed with sign-in
            const result = await window.CustomerAuth.signInWithEmail(email, password);
            if (result.isNewUser) {
                // New user - show phone input
                showStep2();
            } else {
                // Existing user - show logged in state
                showLoggedInState(result.customer);
                showToast('Signed in successfully!', 'success');

                // If we want to auto-continue:
                // handleContinue();
            }
        } catch (error) {
            console.error('Email sign-in error:', error);

            // Checks for "No Account" scenarios - Broad Check
            const errStr = error ? error.toString() : '';
            const errMsg = error.message || '';

            // Handle standard detection
            if (errMsg.includes('NO_ACCOUNT_FOUND') ||
                errStr.includes('NO_ACCOUNT_FOUND') ||
                errMsg.includes('FORCE_REDIRECT_TO_SIGNUP') ||
                errStr.includes('FORCE_REDIRECT_TO_SIGNUP') ||
                errMsg.includes('user-not-found') ||
                errMsg.includes('Sign-in failed: NO_ACCOUNT_FOUND')) {

                showToast('No account found. Redirecting to sign up...', 'warning');
                setTimeout(() => {
                    showStepSignUp();
                }, 1000);
                return;
            }

            let msg = 'Sign-in failed. Please check your credentials.';
            if (error.code === 'auth/invalid-credential') msg = 'Invalid email or password.';
            if (error.code === 'auth/wrong-password') msg = 'Incorrect password.';

            // If the error message starts with "Sign-in failed:", use it directly
            if (error.message && error.message.startsWith('Sign-in failed:')) {
                msg = error.message;
            }

            // CRITICAL CATCH-ALL: If the final message displayed to user contains the keyword, redirect!
            if (msg.includes('NO_ACCOUNT_FOUND')) {
                showToast('No account found. Redirecting to sign up...', 'warning');
                setTimeout(() => {
                    showStepSignUp();
                }, 1000);
                return;
            }

            showToast(msg, 'error');
        } finally {
            setLoading(emailSignInBtn, false);
        }
    }

    /**
     * Handle Email Sign-Up
     */
    async function handleEmailSignUp(e) {
        e.preventDefault();
        console.log('Sign Up form submitted');

        const name = $('#signUpName').value;
        const email = $('#signUpEmail').value;
        const password = $('#signUpPassword').value;

        console.log('Sign Up Data:', { name, email, passwordLength: password ? password.length : 0 });

        if (!name || !email || !password) {
            showToast('Please fill in all fields', 'error');
            return;
        }

        // Password validation removed - allow any password

        setLoading(emailSignUpBtn, true);

        try {
            console.log('Calling signUpWithEmail...');
            const result = await window.CustomerAuth.signUpWithEmail(email, password, name);
            console.log('Sign Up successful:', result);
            // After signup, we need phone number
            showStep2();
            showToast('Account created! Please verify your phone number.', 'success');
        } catch (error) {
            console.error('Sign-up error:', error);
            let msg = 'Sign-up failed: ' + error.message;
            if (error.code === 'auth/email-already-in-use') msg = 'Email is already in use. Please sign in instead.';
            showToast(msg, 'error');
        } finally {
            setLoading(emailSignUpBtn, false);
        }
    }

    /**
     * Handle Google Sign-Up button click (on Sign Up screen)
     */
    async function handleGoogleSignUp() {
        if (!window.CustomerAuth) {
            console.error('CustomerAuth not loaded');
            return;
        }

        // Use ONLY the button from the sign-up step
        const signUpBtn = stepSignUp?.querySelector('.btn-google');
        if (signUpBtn) setLoading(signUpBtn, true);

        try {
            // Step 1: Initiate Google Auth
            temporaryGoogleUser = await window.CustomerAuth.initiateGoogleSignUp();

            // Step 2: Show Password Creation Screen
            showStepGooglePassword();

        } catch (error) {
            console.error('Sign-up error:', error);
            showToast(error.message || 'Sign-up failed. Please try again.', 'error');
        } finally {
            if (signUpBtn) setLoading(signUpBtn, false);
        }
    }

    /**
     * Handle "Continue" button on Google Password Step
     */
    function handleGooglePasswordNext() {
        const password = googleSignUpPassword?.value;
        if (!password) {
            showToast('Please create a password', 'error');
            return;
        }

        if (password.length < 6) {
            showToast('Password must be at least 6 characters', 'error');
            return;
        }

        // Move to Phone Step
        showStep2();
    }

    /**
     * Handle Google Sign-In button click
     */
    async function handleGoogleSignIn() {
        if (!window.CustomerAuth) {
            console.error('CustomerAuth not loaded');
            return;
        }

        setLoading(googleSignInBtn, true);

        try {
            const result = await window.CustomerAuth.signInWithGoogle();

            // Existing user - show logged in state
            showLoggedInState(result.customer);
        } catch (error) {
            console.error('Sign-in error:', error);

            // Check if it's the "no account found" error
            if (error.message === 'NO_ACCOUNT_FOUND') {
                showToast('No account found. Please sign up first.', 'warning');
                // Redirect to sign-up screen
                setTimeout(() => {
                    showStepSignUp();
                }, 1500);
            } else {
                showToast(error.message || 'Sign-in failed. Please try again.', 'error');
            }
        } finally {
            setLoading(googleSignInBtn, false);
        }
    }

    /**
     * Handle complete signup (with phone number)
     */
    async function handleCompleteSignup() {
        if (!window.CustomerAuth) return;

        const phone = phoneInput?.value.trim();

        if (!phone) {
            showToast('Please enter your phone number', 'error');
            phoneInput?.focus();
            return;
        }

        // Validate Indian phone format
        const phoneRegex = /^[6-9]\d{9}$/;
        if (!phoneRegex.test(phone)) {
            showToast('Please enter a valid 10-digit phone number starting with 6-9', 'error');
            phoneInput?.focus();
            return;
        }

        setLoading(completeSignupBtn, true);

        try {
            if (temporaryGoogleUser) {
                // If this is a Google flow, use the stored user and entered password
                const password = googleSignUpPassword?.value;
                if (!password) {
                    throw new Error('Password session lost. Please try again.');
                }

                const customer = await window.CustomerAuth.completeGoogleSignUp(temporaryGoogleUser, password, phone);
                showLoggedInState(customer);
                showToast('Account setup complete!', 'success');
                temporaryGoogleUser = null; // Clear
            } else {
                // Standard flow (email signup or other?)
                // Currently only used for new users who somehow need to just finish profile?
                // But for Google Sign Up flow we have a special case.

                const customer = await window.CustomerAuth.completeSignup(phone);
                showLoggedInState(customer);
                showToast('Account setup complete!', 'success');
            }
        } catch (error) {
            console.error('Signup error:', error);
            showToast(error.message || 'Signup failed. Please try again.', 'error');
        } finally {
            setLoading(completeSignupBtn, false);
        }
    }

    /**
     * Handle continue button (when already logged in)
     */
    function handleContinue() {
        if (onAuthenticatedCallback && window.CustomerAuth) {
            const customer = window.CustomerAuth.getCurrentCustomer();
            onAuthenticatedCallback(customer);
        }
        hide();
    }

    /**
     * Handle sign out button
     */
    async function handleSignOut() {
        if (!window.CustomerAuth) return;

        try {
            await window.CustomerAuth.signOutCustomer();
            showStep1();
            showToast('Signed out successfully', 'success');
        } catch (error) {
            console.error('Sign-out error:', error);
            showToast('Sign-out failed. Please try again.', 'error');
        }
    }

    /**
     * Handle close button or backdrop click
     */
    function handleClose() {
        if (onCancelCallback) {
            onCancelCallback();
        }
        hide();
    }

    /**
     * Set loading state on button
     * @param {HTMLElement} button
     * @param {boolean} loading
     */
    function setLoading(button, loading) {
        if (!button) return;

        if (loading) {
            button.disabled = true;
            button.classList.add('loading');
            button.setAttribute('aria-busy', 'true');
        } else {
            button.disabled = false;
            button.classList.remove('loading');
            button.setAttribute('aria-busy', 'false');
        }
    }

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Export modal API
    window.customerAuthModal = {
        show,
        hide
    };
})();

