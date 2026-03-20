import debounce from '../utils/debounce';
import { initAutocomplete, scrubOrgSelectionParamsOnSubmit } from '../utils/autoComplete';
import getConstant from '../utils/constants';
import { isObject, isArray, isString, isNumber } from '../utils/isType';
import { renderAlert, hideNotifications } from '../utils/notificationHelper';

$(() => {
  // Cache repeatedly used selectors
  const newPlanForm = $('#new_plan');
  const planTemplateID = $('#plan_template_id');
  const templateDropdown = $('#template-dropdown');
  const templateDropdownMenu = $('#template-dropdown-menu');
  const multipleTemplates = $('#multiple-templates');
  const availableTemplates = $('#available-templates');

  const toggleSubmit = () => {
    const tmplt = planTemplateID.val();
    const submitButton = newPlanForm.find('button[type="submit"]');

    // If a template has been selected and it is a string
    if (tmplt && isString(tmplt)) {
      // remove the disabled attribute and make the button clickable
      submitButton.removeAttr('disabled').removeAttr('data-toggle').removeAttr('title');
    } else {
      // otherwise keep it disabled
      submitButton.attr('disabled', true).attr('data-toggle', 'tooltip')
      .attr('title', getConstant('NEW_PLAN_DISABLED_TOOLTIP'));
    }
  };

  // AJAX error function for available template search
  const error = () => {
    renderAlert(getConstant('NO_TEMPLATE_FOUND_ERROR'));
  };

  // Binds a delegated click handler on templateDropdownMenu to handle clicks on template items
  const bindTemplateDropdownMenuClickHandler = () => {
    templateDropdownMenu.on('click', 'a.dropdown-item', (e) => {
      e.preventDefault();
      const target = $(e.currentTarget);
      planTemplateID.val(target.data('id'));
      templateDropdown.text(target.data('title'));
      toggleSubmit();
    });
  }

  // Helper for success() to validate the structure and content of the template response
  const isValidTemplateResponse = (data) => (
    isObject(data) && isObject(data.templates) &&
    isNumber(data.total_templates) && data.total_templates > 0 &&
    ['org_templates', 'priority_templates', 'other_templates'].every(
      (k) => isArray(data.templates[k])
    )
  );

  // Helper for success() to extract total_templates and all template groups from the response
  const extractTemplateData = (data) => {
    const { total_templates: totalTemplates, templates } = data;
    const {
      org_templates: orgTemplates,
      priority_templates: priorityTemplates,
      other_templates: otherTemplates
    } = templates;

    return { totalTemplates, orgTemplates, priorityTemplates, otherTemplates };
  };

  // Helper for success() that creates a template item
  const createTemplateItem = (template) => {
    const a = $('<a>', {
      class: 'dropdown-item',
      href: '#',
      'data-id': template.id,
      'data-title': template.title,
    }).text(template.title);
    return a;
  };

  // Helper for success() that appends a group of templates with a header
  // for organization in the template dropdown menu
  const appendGroup = (menu, header, templates) => {
    if (templates.length === 0) return;

    menu.append(`<h6 class="dropdown-header text-muted">${header}</h6>`);
    templates.forEach((t) => menu.append(createTemplateItem(t)));
    menu.append('<div class="dropdown-divider"></div>');
  };

  // Helper for success() that appends the "Show more templates" button and other templates
  const appendShowMoreSection = (menu, otherTemplates) => {
    if (otherTemplates.length === 0) return;

    const showMore = $(`
      <button type="button" class="btn btn-secondary" id="show-more-templates">
        ${getConstant('SHOW_MORE_TEMPLATES')}
      </button>
    `);
    
    menu.append(showMore);
    // Hidden section for the "other" templates
    const hiddenContainer = $('<div id="extra-templates" style="display:none;"></div>');
    menu.append(hiddenContainer);

    // When clicked, expand the hidden templates without closing dropdown
    showMore.on('click', (e) => {
      e.preventDefault();
      e.stopPropagation(); // prevent closing dropdown

      hiddenContainer.empty(); // clear before adding
      hiddenContainer.append(`<h6 class="dropdown-header text-muted">${getConstant('OTHER_TEMPLATES')}</h6>`);
      otherTemplates.forEach((t) => hiddenContainer.append(createTemplateItem(t)));

      hiddenContainer.slideDown(10);
      showMore.remove(); // remove the button after expansion
    });
  };

  // Helper for resizing width and height of templateDropdownMenu
  // Matches width to that of the dropdown button (prevents resizing when "Show more..." is clicked)
  // Sets max-height to avoid extending beyond the footer
  const resizeTemplateDropdownMenu = () => {
    const templateDropdownEl = templateDropdown.get(0);
    const templateDropdownMenuEl = templateDropdownMenu.get(0);
    const footerEl = document.getElementById('footer-navbar');

    // Return early if any required element is missing or dropdown is not visible
    if (!(templateDropdownEl && templateDropdownMenuEl && footerEl  && templateDropdown.is(':visible'))) return;

    // Set width
    templateDropdownMenu.outerWidth(templateDropdown.outerWidth());

    // Set maxHeight
    const dropdownRect = templateDropdownEl.getBoundingClientRect();
    const footerRect = footerEl.getBoundingClientRect();

    // Ideal location for dropdown to end is middle of the footer
    const footerMiddle = (footerRect.bottom + footerRect.top) / 2;

    const spaceAvailable = footerMiddle - dropdownRect.bottom;

    if (spaceAvailable > 0) {
      templateDropdownMenuEl.style.maxHeight = `${spaceAvailable}px`;
    }
  };

  // AJAX success function for available template search
  const success = (data) => {
    hideNotifications();
    templateDropdownMenu.empty();

    if (!isValidTemplateResponse(data)) return error();
    const { orgTemplates, priorityTemplates, otherTemplates, totalTemplates } = extractTemplateData(data);
  
    // Add main groups
    appendGroup(templateDropdownMenu, getConstant('ORG_TEMPLATES'), orgTemplates);
    appendGroup(templateDropdownMenu, getConstant('PRIORITY_TEMPLATES'), priorityTemplates);
    // Add “Show more templates”
    appendShowMoreSection(templateDropdownMenu, otherTemplates);

    // If there is only one template, set the input field value and submit the form
    // otherwise show the dropdown list and the 'Multiple templates found message'
    if (totalTemplates === 1) {
      // Get the only template
      const onlyTemplate = [...orgTemplates, ...priorityTemplates, ...otherTemplates][0];
      // Ensure there is in fact a template
      if (!onlyTemplate) return error();

      templateDropdown.text(onlyTemplate.title);
      planTemplateID.val(onlyTemplate.id);
      multipleTemplates.hide();
      availableTemplates.fadeOut();
    } else {
      multipleTemplates.show();
      availableTemplates.fadeIn();
    }
    resizeTemplateDropdownMenu();
    toggleSubmit();
  };

  // Function to reset the template dropdown
  const resetTemplateDropdown = (isValidOrg = false) => {
    // Always fade out and reset hidden value
    availableTemplates.fadeOut();
    planTemplateID.val('');

    if (isValidOrg) {
      // Reset dropdown text
      templateDropdown.text(getConstant('SELECT_TEMPLATE'));
      // Clear any existing menu items
      templateDropdownMenu.empty();
    }
  };

  // TODO: Refactor this whole thing when we redo the create plan
  //       workflow and use js.erb instead!
  const getValue = (context) => {
    if (context.length > 0) {
      const hidden = $(context).find('.autocomplete-result');
      if (hidden.length > 0 && hidden.val().length > 0
         && hidden.val() !== '{}' && hidden.val() !== '{"name":""}') {
        return hidden.val();
      }
    }
    return '{}';
  };

  const validOptions = (context) => {
    let ret = false;
    if ($(context).length > 0) {
      const checkbox = $(context).find('input.toggle-autocomplete');
      const val = getValue(context);

      if (val.length > 0 && val !== '{}') {
        const json = JSON.parse(val);
        // If the json ONLY contains a name then it is not a valid selection
        ret = (checkbox.prop('checked') || json.id !== undefined);
      } else {
        // Otherwise just focus on the checkbox
        ret = checkbox.prop('checked');
      }
    }
    return ret;
  };

  // When one of the autocomplete fields changes, fetch the available templates
  const handleComboboxChange = debounce(() => {
    const orgContext = $('#research-org-controls');
    const funderContext = $('#funder-org-controls');
    const validOrg = validOptions(orgContext);
    resetTemplateDropdown(validOrg)

    // DMP Assistant does not require a funder for creating a plan. Instead the
    // Plan controller will search for the default funder when creating the
    // plan. In our current case this will be "Portage Network"
    // const validFunder = validOptions(funderContext);

    if (!validOrg) {
      toggleSubmit();
    } else {
      let orgId = orgContext.find('input[id$="org_id"]').val();
      let funderId = funderContext.find('input[id$="funder_id"]').val(); // funder id is default to 8 (Portage Network)

      // For some reason Rails freaks out it everything is empty so send
      // the word "none" instead and handle on the controller side
      if (orgId.length <= 0) {
        orgId = '"none"';
      }
      if (funderId.length <= 0) {
        funderId = '"none"';
      }
      // Pass '8'(portage network) for DMP Assistant directly to funder_id,
      // Otherwise it will automatically add an extra 'name' attribute
      const data = `{"research_org_id":${orgId},"funder_id":8}`;
      // Fetch the available templates based on the funder and research org selected
      $.get($('#template-option-target').val(),
        {
          plan: JSON.parse(data),
        }).done(success).fail(error);
    }
  }, 150);

  // When one of the checkboxes is clicked, disable the autocomplete input and clear its contents
  const handleCheckboxClick = (autocomplete, checkbox) => {
    // Clear and then Disable/Enable the textbox and hide
    // any textbox warnings
    const checked = checkbox.prop('checked');
    autocomplete.val('');
    autocomplete.prop('disabled', checked);
    autocomplete.siblings('.autocomplete-result').val('');
    autocomplete.siblings('.autocomplete-warning').hide();

    handleComboboxChange();
  };

  const initOrgSelection = (context) => {
    const section = $(context);

    if (section.length > 0) {
      initAutocomplete(`${context} .autocomplete`);

      const autocomplete = $(section).find('.autocomplete');
      const hidden = autocomplete.siblings('.autocomplete-result');
      const checkbox = $(section).find('input.toggle-autocomplete');

      hidden.on('change', () => {
        handleComboboxChange();
      });

      checkbox.on('click', () => {
        handleCheckboxClick(autocomplete, checkbox);
      });

      if (checkbox.prop('checked')) {
        handleCheckboxClick(autocomplete, checkbox);
      }
    }
  };

  ['#research-org-controls', '#funder-org-controls'].forEach((el) => {
    if ($(el).length > 0) {
      initOrgSelection(el);
    }
  });

  const defaultVisibility = $('#plan_visibility').val();

  // When the user checks the 'mock project' box we need to set the
  // visibility to 'is_test'
  newPlanForm.find('#is_test').click((e) => {
    $('#plan_visibility').val(($(e.currentTarget)[0].checked ? 'is_test' : defaultVisibility));
  });

  // Initialize the form
  bindTemplateDropdownMenuClickHandler();
  handleComboboxChange();
  // Scrub out the large arrays of data used for the Org Selector JS so that they
  // are not a part of the form submissiomn
  scrubOrgSelectionParamsOnSubmit(newPlanForm);
  toggleSubmit();
});
