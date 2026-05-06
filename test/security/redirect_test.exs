defmodule Relyra.Security.RedirectTest do
  use ExUnit.Case, async: true

  alias Relyra.Security.Redirect
  alias Relyra.Error

  describe "safe_local_redirect/2" do
    test "accepts valid local path" do
      assert {:ok, "/dashboard"} = Redirect.safe_local_redirect("/dashboard")
    end

    test "rejects protocol-relative paths" do
      assert {:error, %Error{type: :invalid_redirect}} = Redirect.safe_local_redirect("//evil.com")
    end

    test "rejects absolute URLs" do
      assert {:error, %Error{type: :invalid_redirect}} = Redirect.safe_local_redirect("http://evil.com")
      assert {:error, %Error{type: :invalid_redirect}} = Redirect.safe_local_redirect("https://evil.com")
    end

    test "rejects nil" do
      assert {:error, %Error{type: :invalid_redirect}} = Redirect.safe_local_redirect(nil)
    end

    test "rejects relative paths not starting with /" do
      assert {:error, %Error{type: :invalid_redirect}} = Redirect.safe_local_redirect("dashboard")
    end
  end
end
