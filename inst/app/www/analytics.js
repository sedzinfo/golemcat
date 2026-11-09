// Reports the tabs of the app and the downloads of the PDF report to Google Analytics, as pages and downloads.
// gtag() only exists once the visitor accepts on the cookie banner (consent.js), so nothing is sent before.
$(document).on('shown.bs.tab', 'a[data-bs-toggle="tab"]', function(e) {
  if (typeof gtag !== 'function') return;
  const tab = $(e.target).attr('data-value');
  gtag('event', 'page_view', {
    page_title: tab,
    page_location: location.origin + location.pathname + '#' + encodeURIComponent(tab)
  });
});

$(document).on('click', '.shiny-download-link', function() {
  if (typeof gtag !== 'function') return;
  gtag('event', 'file_download', {
    file_extension: 'pdf',
    link_text: 'PDF report'
  });
});
