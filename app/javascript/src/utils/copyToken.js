const initCopyToken = () => {
  document.addEventListener('click', function (e) {
    const button = e.target.closest('#copy-token-btn');
    if (!button) return;

    e.preventDefault();

    const tokenInput = document.getElementById('api-token-val');
    if (!tokenInput) return;

    const originalHTML = button.innerHTML;

    navigator.clipboard.writeText(tokenInput.value).then(() => {
      // Replace button contents with check icon
      button.innerHTML = '<i class="fa fa-circle-check" aria-hidden="true"></i>';

      // Restore after 2s
      setTimeout(() => {
        button.innerHTML = originalHTML;
      }, 2000);
    }).catch(() => {
      alert('Failed to copy token');
    });
  });
};

initCopyToken();
