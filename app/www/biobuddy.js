function setBioType() {
  h = document.querySelector("#out_card_b .tab-pane.show.active");
  val = h.attributes.biotype.value;
  Shiny.setInputValue('biotype', val);
}

function tooltipsOn() {
  $('[data-toggle=\"tooltip\"]').tooltip({ container: 'body' });
}

function setTabToCustomize() {
  document.getElementById('tab-customize_tab').classList.add('active', 'show');
  document.getElementById('tab-showcase_tab').classList.remove('active', 'show');
}

// Temp solution to programmatically hiding sidebar
function collapseSidebar() {
  document.querySelectorAll('.navbar-toggler')[0].click();
}

// Copy to clipboard functionality
function copyToClipboard(elementId) {
  const element = document.getElementById(elementId);
  if (!element) {
    console.error('Element not found:', elementId);
    return;
  }
  
  const text = element.textContent || element.innerText;
  
  // Use the modern Clipboard API if available
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(text).then(function() {
      showCopySuccess(elementId);
    }).catch(function(err) {
      console.error('Failed to copy text: ', err);
      fallbackCopyTextToClipboard(text, elementId);
    });
  } else {
    // Fallback for older browsers or non-secure contexts
    fallbackCopyTextToClipboard(text, elementId);
  }
}

// Fallback copy method for older browsers
function fallbackCopyTextToClipboard(text, elementId) {
  const textArea = document.createElement("textarea");
  textArea.value = text;
  
  // Avoid scrolling to bottom
  textArea.style.top = "0";
  textArea.style.left = "0";
  textArea.style.position = "fixed";
  textArea.style.opacity = "0";
  
  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();
  
  try {
    const successful = document.execCommand('copy');
    if (successful) {
      showCopySuccess(elementId);
    } else {
      showCopyError(elementId);
    }
  } catch (err) {
    console.error('Fallback: Oops, unable to copy', err);
    showCopyError(elementId);
  }
  
  document.body.removeChild(textArea);
}

// Show success feedback
function showCopySuccess(elementId) {
  const button = document.querySelector(`button[onclick="copyToClipboard('${elementId}')"]`);
  if (button) {
    const originalHTML = button.innerHTML;
    button.innerHTML = '<i class="fa-solid fa-check"></i> Copied!';
    button.classList.remove('btn-outline-primary');
    button.classList.add('btn-success');
    
    setTimeout(function() {
      button.innerHTML = originalHTML;
      button.classList.remove('btn-success');
      button.classList.add('btn-outline-primary');
    }, 2000);
  }
}

// Show error feedback
function showCopyError(elementId) {
  const button = document.querySelector(`button[onclick="copyToClipboard('${elementId}')"]`);
  if (button) {
    const originalHTML = button.innerHTML;
    button.innerHTML = '<i class="fa-solid fa-times"></i> Failed';
    button.classList.remove('btn-outline-primary');
    button.classList.add('btn-danger');
    
    setTimeout(function() {
      button.innerHTML = originalHTML;
      button.classList.remove('btn-danger');
      button.classList.add('btn-outline-primary');
    }, 2000);
  }
}
