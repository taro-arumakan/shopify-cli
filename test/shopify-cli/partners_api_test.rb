require "test_helper"

module ShopifyCli
  class PartnersAPITest < MiniTest::Test
    include TestHelpers::Project

    def test_query_calls_partners_api
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns("token123")
      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.expects(:query).with("query", variables: {}).returns("response")
      assert_equal "response", PartnersAPI.query(@context, "query")
    end

    def test_query_can_reauth
      Shopifolk.stubs(:check).returns(false)
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns("token123")

      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.stubs(:query).raises(API::APIRequestUnauthorizedError).then.returns("response")

      @identity_auth_client = mock
      ShopifyCli::IdentityAuth
        .expects(:new)
        .with(ctx: @context).returns(@identity_auth_client)
      @identity_auth_client
        .expects(:reauthenticate)

      assert_equal "response", PartnersAPI.query(@context, "query")
    end

    def test_query_fails_gracefully_when_unable_to_authenticate
      Shopifolk.stubs(:check).returns(false)
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns("token123").twice

      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub).twice
      api_stub.expects(:query).raises(API::APIRequestUnauthorizedError).twice

      @identity_auth_client = mock
      ShopifyCli::IdentityAuth
        .expects(:new)
        .with(ctx: @context).returns(@identity_auth_client)
      @identity_auth_client
        .expects(:authenticate)

      io = capture_io_and_assert_raises(ShopifyCli::Abort) do
        PartnersAPI.query(@context, "query")
      end
      assert_message_output(
        io: io,
        expected_content: [
          @context.message("core.api.error.failed_auth"),
        ]
      )
    end

    def test_query_fails_gracefully_without_partners_account
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns("token123")
      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.expects(:query).raises(API::APIRequestNotFoundError)
      @context.expects(:puts).with(@context.message("core.partners_api.error.account_not_found", ShopifyCli::TOOL_NAME))
      PartnersAPI.query(@context, "query")
    end

    def test_query
      ShopifyCli::DB.expects(:get).with(:partners_exchange_token).returns("token123")
      api_stub = stub
      PartnersAPI.expects(:new).with(
        ctx: @context,
        token: "token123",
        url: "https://partners.shopify.com/api/cli/graphql",
      ).returns(api_stub)
      api_stub.expects(:query).with("query", variables: {}).returns("response")
      assert_equal "response", PartnersAPI.query(@context, "query")
    end
  end
end
