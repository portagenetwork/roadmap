$(() => {
  const scopeField = $('#doorkeeper_application_scopes');

  if (scopeField.length === 0) {
    return;
  }

  const versionRadios = $('.api-version-toggle');
  const scopeGroups = $('.api-scope-group');
  const scopeRadios = $('.api-scope-radio');

  // Snapshot of what the server rendered as checked on page load (i.e. the
  // scope saved in the DB). Never updated afterwards, so switching back to
  // the saved API always restores the persisted scope. Versions with no
  // checked radio (every API other than the saved one) get no entry and fall
  // back to their default scope.
  const savedSelections = {};
  scopeGroups.each(function () {
    const checkedRadio = $(this).find('.api-scope-radio:checked').first();
    if (checkedRadio.length > 0) {
      savedSelections[$(this).data('apiScopeGroup')] = checkedRadio.val();
    }
  });

  const showGroupFor = (version) => {
    scopeGroups.each(function () {
      $(this).toggleClass('d-none', $(this).data('apiScopeGroup') !== version);
    });
  };

  // Priority: saved (DB) scope -> group default -> first option.
  const selectScopeForVersion = (version) => {
    const group = scopeGroups.filter(`[data-api-scope-group="${version}"]`);
    const groupRadios = group.find('.api-scope-radio');

    let target = groupRadios.filter(`[value="${savedSelections[version]}"]`);
    if (target.length === 0) {
      target = groupRadios.filter(`[value="${group.data('defaultScope')}"]`);
    }
    if (target.length === 0) {
      target = groupRadios.first();
    }

    scopeRadios.prop('checked', false);

    if (target.length > 0) {
      target.prop('checked', true);
      scopeField.val(target.val());
    }
  };

  versionRadios.on('change', function () {
    const version = $(this).val();
    showGroupFor(version);
    selectScopeForVersion(version);
  });

  // Manual scope picks only update the hidden field; they are intentionally
  // not remembered across version switches.
  scopeRadios.on('change', function () {
    scopeField.val($(this).val());
  });
});
