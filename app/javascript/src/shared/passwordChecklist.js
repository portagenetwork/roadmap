
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

  // Map the rule names to their icons
  // (See app/views/shared/_password_checklist.html.erb)
  const ruleIconsMap = Object.fromEntries(
    Object.keys(rules).map(rule => {
      const li = passwordRequirements.querySelector(`li[data-rule="${rule}"]`);
      const icon = li?.querySelector('i');
      return [rule, icon];
    })
  );

  const updateRequirements = (pw) => {
    for (const [ruleName, ruleValidator] of Object.entries(rules)) {
      const icon = ruleIconsMap[ruleName];
      if (!icon) continue;

      const valid = ruleValidator(pw);
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
