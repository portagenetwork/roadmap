
const passwordChecklist = () => {
  const passwordInputs = [
    document.getElementById('user_password'),
    // Some forms pre-append 'new' to ID names
    document.getElementById('new_user_password')
  ].filter(Boolean); // Filter out nulls if one doesn't exist

  const passwordRequirements = document.getElementById('password-checklist')

  // Exit if relevant elements are not on this page
  if (passwordInputs.length === 0 || !passwordRequirements) return;

  const rules = {
    length: (pw) => pw.length >= 8,
    uppercase: (pw) => /[A-Z]/.test(pw),
    lowercase: (pw) => /[a-z]/.test(pw),
    digit: (pw) => /[0-9]/.test(pw),
    // Only common ASCII special characters (not emojis, spaces, etc.)
    special: (pw) => /[!@#$%^&*()_\-+=\[\]{};:'",.<>?/\\|`~]/.test(pw),
  };

  const updateRequirements = (pw) => {
    for (const rule in rules) {
      const li = passwordRequirements.querySelector(`li[data-rule="${rule}"]`);
      const icon = li?.querySelector('i');

      if (!icon) continue;

      const valid = rules[rule](pw);
      icon.classList.toggle('fa-circle-check', valid);
      icon.classList.toggle('fa-circle-xmark', !valid);
    }
  };

  passwordInputs.forEach(input => {
    input.addEventListener('input', (e) => {
      // passwordRequirements element is hidden by default
      if (!passwordRequirements.classList.contains('visible')) {
        passwordRequirements.classList.add('visible');
      }
      updateRequirements(e.target.value);
    });
  });
};

passwordChecklist();
