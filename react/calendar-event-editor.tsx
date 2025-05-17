import * as React from "react";
import * as ReactDOM from "react-dom/client";
import ExistingEvent from "./components/Events/ExistingEvent";
declare global {
  interface Window {
    // Since TypeScript requires a definition for all methods, let's tell it how to handle the javascript objects already in the page
    showEventForm(object): void;
    showNewEventForm(info): void;
    CRM: {
      // we need to access this method of CRMJSOM, so let's tell TypeScript how to use it
      refreshAllFullCalendarSources(): void;
    };
    // React does have it's own i18next implementation, but for now, lets use the one that's already being loaded
    i18next: {
      t(string): string;
    };
    // instead of loading the whole react-moment class, we can just use the one that's already on window.
    moment: any;
  }
}

// Keep track of the root to unmount it
let root = null;

window.showEventForm = function (event) {
  const container = document.getElementById("calendar-event-react-app");
  
  // Cleanup previous render
  if (root) {
    root.unmount();
    window.CRM.refreshAllFullCalendarSources();
  }
  
  // Create a new rendering
  root = ReactDOM.createRoot(container);
  const unmount = function() {
    if (root) {
      root.unmount();
      window.CRM.refreshAllFullCalendarSources();
    }
  };
  
  root.render(
    <ExistingEvent onClose={unmount} eventId={event.id} />
  );
};

window.showNewEventForm = function (info) {
  const { start, end } = info;
  const container = document.getElementById("calendar-event-react-app");
  
  // Cleanup previous render
  if (root) {
    root.unmount();
    window.CRM.refreshAllFullCalendarSources();
  }
  
  // Create new root
  root = ReactDOM.createRoot(container);
  const unmount = function() {
    if (root) {
      root.unmount();
      window.CRM.refreshAllFullCalendarSources();
    }
  };
  
  root.render(
    <ExistingEvent
      onClose={unmount}
      eventId={0}
      start={start}
      end={end}
    />
  );
};
