defmodule Lanttern.Identity.UserNotifier do
  @moduledoc """
  The `UserNotifier` schema
  """

  import Swoosh.Email

  # alias Lanttern.Identity.User
  alias Lanttern.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body, html \\ nil) do
    email =
      new()
      |> to(recipient)
      |> from({"Lanttern", "no-reply@lanttern.org"})
      |> subject(subject)
      |> text_body(body)

    email =
      if html,
        do: html_body(email, html),
        else: email

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver login code to user's email.
  """
  def deliver_login_code(user, code) do
    body = """

    ==============================

    Hi #{user.email},

    Your Lanttern sign in code is:

    #{code}

    This code expires in 5 minutes.

    If you didn't request this code, please ignore this email.

    ==============================

    """

    html = """
    <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <title>Lanttern sign in code</title>

          <!-- Web Font Import with fallback -->
          <style>
              @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@900&family=Open+Sans:wght@400,600&display=swap');

              /* Basic reset for email clients */
              body, table, td, p, a, li, blockquote {
                  -webkit-text-size-adjust: 100%;
                  -ms-text-size-adjust: 100%;
              }

              table, td {
                  mso-table-lspace: 0pt;
                  mso-table-rspace: 0pt;
              }

              img {
                  -ms-interpolation-mode: bicubic;
                  border: 0;
                  height: auto;
                  line-height: 100%;
                  outline: none;
                  text-decoration: none;
              }

              /* Mobile responsive styles */
              @media screen and (max-width: 600px) {
                  .mobile-full-width {
                      width: 100% !important;
                  }

                  .mobile-padding {
                      padding-left: 20px !important;
                      padding-right: 20px !important;
                  }

                  .mobile-center {
                      text-align: center !important;
                  }

                  .mobile-hide {
                      display: none !important;
                  }
              }
          </style>
      </head>

      <body style="margin: 0; padding: 0; background-color: #e2e8f0; font-family: 'Open Sans', Helvetica, sans-serif;">
          <!-- Wrapper table for Outlook -->
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #e2e8f0;">
              <tr>
                  <td align="center" style="padding: 20px 0;">

                      <!-- Main container -->
                      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" class="mobile-full-width" style="background-color: #ffffff; max-width: 600px; margin: 0 auto;">

                          <!-- Header -->
                          <tr>
                              <td style="padding: 40px 40px 20px 40px; text-align: center; background-color: #00d3f2;" class="mobile-padding">
                                <h1 style="margin: 0 0 20px 0; font-family: 'Montserrat', Helvetica, sans-serif; font-size: 36px; font-weight: 900; color: #314158; line-height: 1; text-align: center">
                                    Lanttern
                                </h1>
                              </td>
                          </tr>

                          <!-- Main content -->
                          <tr>
                              <td style="padding: 40px;" class="mobile-padding">

                                  <!-- Greeting -->
                                  <h2 style="margin: 0 0 20px 0; font-family: 'Montserrat', Helvetica, sans-serif; font-size: 28px; font-weight: 900; color: #314158; line-height: 1.2;">
                                      Your sign in code
                                  </h2>

                                  <p style="margin: 0 0 20px 0; font-family: 'Open Sans', Helvetica, sans-serif; font-size: 16px; line-height: 1.5; color: #314158;">
                                      Hi, #{user.email}!
                                  </p>

                                  <p style="margin: 0 0 30px 0; font-family: 'Open Sans', Helvetica, sans-serif; font-size: 16px; line-height: 1.5; color: #314158;">
                                      Enter this code to sign into your account:
                                  </p>

                                  <!-- Code display -->
                                  <div style="text-align: center; margin: 30px 0;">
                                      <span style="background-color: #f1f5f9; border: 2px solid #e2e8f0; border-radius: 8px; display: inline-block; font-family: 'Montserrat', monospace; font-size: 32px; font-weight: 900; letter-spacing: 0.25em; padding: 20px 30px; color: #314158;">
                                          #{code}
                                      </span>
                                  </div>

                                  <p style="margin: 30px 0 0 0; font-family: 'Open Sans', Helvetica, sans-serif; font-size: 14px; line-height: 1.5; color: #64748b; text-align: center;">
                                      This code expires in 5 minutes.<br />
                                      If you didn't request this code, please ignore this email.
                                  </p>
                              </td>
                          </tr>
                      </table>
                  </td>
              </tr>
          </table>
      </body>
    </html>
    """

    deliver(user.email, "Sign in code", body, html)
  end
end
