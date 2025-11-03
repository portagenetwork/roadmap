import debounce from '../utils/debounce';
import { initAutocomplete, scrubOrgSelectionParamsOnSubmit } from '../utils/autoComplete';
import getConstant from '../utils/constants';
import { isObject, isString } from '../utils/isType';
import { renderAlert, hideNotifications } from '../utils/notificationHelper';

$(() => {
  const toggleSubmit = () => {
    const tmplt = $('#plan_template_id').val();
    const submitButton = $('#new_plan button[type="submit"]');

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

  // Helper for success() that creates a clickable template item
  const createTemplateItem = (template) => {
    const title = $('<div>').text(template.title).html();
    const item = $(`<a class="dropdown-item" href="#" data-id="${template.id}">${title}</a>`);

    item.on('click', (e) => {
      e.preventDefault()
      $('#templateDropdown').text(template.title);
      $('#plan_template_id').val(template.id);
      toggleSubmit();
    });

    return item;
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
      <button type="button" class="btn btn-default" id="show-more-templates">
        Show more templates
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
      hiddenContainer.append('<h6 class="dropdown-header text-muted">Additional Alliance Templates</h6>');
      otherTemplates.forEach((t) => hiddenContainer.append(createTemplateItem(t)));

      hiddenContainer.slideDown(10);
      showMore.remove(); // remove the button after expansion
    });
  };

  // Helper function to adjust the height of the template dropdown
  // and make sure it does not extend beyond the footer
  const adjustDropdownMaxHeight = () => {
    const dropdown = document.getElementById('templateDropdown');
    const dropdownMenu = document.getElementById('template-dropdown-menu');
    const footer = document.getElementById('footer-navbar');

    const dropdownRect = dropdown.getBoundingClientRect();
    const footerRect = footer.getBoundingClientRect();

    // Ideal location for dropdown to end is middle of the footer
    const footerMiddle = (footerRect.bottom + footerRect.top) / 2;

    const spaceAvailable = footerMiddle - dropdownRect.bottom;

    if (spaceAvailable > 0) {
      dropdownMenu.style.maxHeight = `${spaceAvailable}px`;
    }
  };


  // AJAX success function for available template search
  const success = (data) => {
    hideNotifications();
    const menu = $('#template-dropdown-menu');
    menu.empty();

    if (!isObject(data) || !isObject(data.templates) || data.total_templates === 0) return error();
    const templates = data.templates;
  
    // Add main groups
    appendGroup(menu, 'Organisational Templates', templates.org_templates);
    appendGroup(menu, 'Alliance General Templates', templates.priority_templates);
    // Add “Show more templates”
    appendShowMoreSection(menu, templates.other_templates);

    // If there is only one template, set the input field value and submit the form
    // otherwise show the dropdown list and the 'Multiple templates found message'
    if (data.total_templates === 1) {
      // Get the first and only template across all groups
      const onlyTemplate = [
        ...templates.org_templates,
        ...templates.priority_templates,
        ...templates.other_templates
      ][0]
      $('#templateDropdown').text(onlyTemplate.title);
      $('#plan_template_id').val(onlyTemplate.id);
      $('#multiple-templates').hide();
      $('#available-templates').fadeOut();
    } else {
      $('#multiple-templates').show();
      $('#available-templates').fadeIn();
    }

    const dropdown = document.getElementById('templateDropdown');
    // offsetParent returns the nearest ancestor that has a position other than static
    // offsetParent property returns null if the element is not visible
    const dropdownIsVisible = dropdown.offsetParent !== null

    // Adjust the height of the dropdown when it is visible
    if (dropdown && dropdownIsVisible) {
      adjustDropdownMaxHeight();
    }

    toggleSubmit();
  };

  // Function to reset the template dropdown
  const resetTemplateDropdown = (isValidOrg = false) => {
    // Always fade out and reset hidden value
    $('#available-templates').fadeOut();
    $('#plan_template_id').val('');

    if (isValidOrg) {
      // Reset dropdown text
      $('#templateDropdown').text('Please select a template');
      // Clear any existing menu items
      $('#template-dropdown-menu').empty();
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
  $('#new_plan #is_test').click((e) => {
    $('#plan_visibility').val(($(e.currentTarget)[0].checked ? 'is_test' : defaultVisibility));
  });

  // Initialize the form
  $('#new_plan #available-templates').hide();
  handleComboboxChange();
  // Scrub out the large arrays of data used for the Org Selector JS so that they
  // are not a part of the form submissiomn
  scrubOrgSelectionParamsOnSubmit('#new_plan');
  toggleSubmit();
});
