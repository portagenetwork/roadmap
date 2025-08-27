
const initPasswordChecklist = () => {

  // Some forms pre-append 'new' to ID names
  const passwordInput = document.getElementById('user_password') || document.getElementById('new_user_password');
  
  const passwordChecklist = document.getElementById('password-checklist')
  // Exit if relevant elements are not on this page
  if (!passwordInput|| !passwordChecklist) return;

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

  const updateChecklistIcons = (pw) => {
    for (const [ruleName, ruleValidator] of Object.entries(rules)) {
      const icon = ruleIconsMap[ruleName];
      if (!icon) continue;

      const valid = ruleValidator(pw);
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
