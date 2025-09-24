
const initPasswordChecklist = () => {

  // Some forms pre-append 'new' to ID names
  const passwordInput = document.getElementById('user_password') || document.getElementById('new_user_password');
  
  const passwordChecklist = document.getElementById('password-checklist')
  // Exit if relevant elements are not on this page
  if (!passwordInput|| !passwordChecklist) return;

  // Use RegExp's .test() method for validating rules
  // (https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp/test)
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
      const li = passwordChecklist.querySelector(`li[data-rule="${rule}"]`);
      const icon = li?.querySelector('i');
      return [rule, icon];
    })
  );

  // Updates the checklist icons to reflect which password rules are satisfied.
  const updateChecklistIcons = (pw) => {
    // Loop over each of the defined rules
    for (const [ruleName, ruleValidator] of Object.entries(rules)) {
      // Get the DOM icon mapped to this rule
      const icon = ruleIconsMap[ruleName];
      if (!icon) continue;

      // Validate current password against current rule
      const valid = ruleValidator(pw);
      // Update icons accordingly: ✔ if valid, ✖ if invalid
      icon.classList.toggle('fa-circle-check', valid);
      icon.classList.toggle('fa-circle-xmark', !valid);
    }
  };

  passwordInput.addEventListener('input', (e) => {
    // passwordChecklist element is hidden by default
    if (!passwordChecklist.classList.contains('visible')) {
      passwordChecklist.classList.add('visible');
    }
    updateChecklistIcons(e.target.value);
  });
};

initPasswordChecklist();
