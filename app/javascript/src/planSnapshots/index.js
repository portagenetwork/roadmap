$(() => {
  const toggleBtn = document.getElementById('btn_toggle_snapshot_form');
  const cancelBtn = document.getElementById('btn_cancel_snapshot');
  const panel = document.getElementById('snapshot_creation_panel');
  const publicRadio = document.getElementById('snapshot_visibility_public');
  const privateRadio = document.getElementById('snapshot_visibility_private');
  const warning = document.getElementById('snapshot_public_warning');

  if (!toggleBtn || !panel) return;

  // Toggle inline card display
  toggleBtn.addEventListener('click', () => {
    panel.classList.toggle('d-none');
  });

  if (cancelBtn) {
    cancelBtn.addEventListener('click', () => {
      panel.classList.add('d-none');
    });
  }

  // Dynamic warning display based on radio selection
  const updateWarningVisibility = () => {
    if (publicRadio && warning) {
      warning.classList.toggle('d-none', !publicRadio.checked);
    }
  };

  if (publicRadio) publicRadio.addEventListener('change', updateWarningVisibility);
  if (privateRadio) privateRadio.addEventListener('change', updateWarningVisibility);
});
