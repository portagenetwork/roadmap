const initCopyToken = () => {
  const tokenInput = document.getElementById('api-token-val');
  const copyButton = document.getElementById('copy-token-btn');

  // Exit early if elements are missing
  if (!tokenInput || !copyButton) return;

  const originalHTML = copyButton.innerHTML;

  copyButton.addEventListener('click', (e) => {
    e.preventDefault();

    navigator.clipboard.writeText(tokenInput.value).then(() => {
      // Replace button contents with check icon
      copyButton.innerHTML = '<i class="fa fa-circle-check" aria-hidden="true"></i>';

      // Restore after 2s
      setTimeout(() => {
        copyButton.innerHTML = originalHTML;
      }, 2000);
    }).catch(() => {
      alert('Failed to copy token');
    });
  });
};

initCopyToken();
