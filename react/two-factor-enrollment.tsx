import * as React from "react";
import * as ReactDOM from "react-dom/client";
import UserTwoFactorEnrollment from "./components/UserSecurity/UserTwoFactorEnrollment";

declare global {
  interface Window {
    // React does have it's own i18next implementation, but for now, lets use the one that's already being loaded
    i18next: {
      t(string): string;
    };
  }
}
$(document).ready(function () {
  const container = document.getElementById("two-factor-enrollment-react-app");
  const root = ReactDOM.createRoot(container);
  root.render(<UserTwoFactorEnrollment />);
});
