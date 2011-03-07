require 'spec_helper'
require 'active_support/json'

describe Sequencescape::Batch do
  REQUEST_HEADERS  = { :headers => {'Accept'=>'application/json', 'Cookie'=>'WTSISignOn=testing', 'X-Sequencescape-Client-Id'=>'authorised'} }
  RESPONSE_HEADERS = { 'Content-Type' => 'application/json' }

  ROOT_JSON = {
    pipelines: { actions: { read: "http://api.example.com/api/1/pipelines" } },
    batches:   { actions: { read: "http://api.example.com/api/1/batches"   } },
    requests:  { actions: { read: "http://api.example.com/api/1/requests"  } },
    asset:     { actions: { read: "http://api.example.com/api/1/assets"    } }
  }
  PIPELINE_JSON = {
    pipeline: {
      actions: {
        read: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE"
      },

      batches: {
        actions: {
          read: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches",
          create: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches"
        }
      },
      requests: {
        actions: {
          read: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/requests"
        }
      }
    }
  }
  REQUESTS_JSON = {
    actions: {
      read: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/requests",
      first: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/requests",
      last: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/requests"
    },
    requests: [
      {
        actions: {
          read: "http://api.example.com/api/1/REQUEST_UUID_1"
        },

        uuid: 'REQUEST_UUID_1',

        target_asset: {
          actions: {
            read: "http://api.example.com/api/1/TARGET_ASSET_UUID_1"
          },

          uuid: 'TARGET_ASSET_UUID_1',
          name: 'Target asset 1',
          barcode: 987654321
        }
      },
      {
        actions: {
          read: "http://api.example.com/api/1/REQUEST_UUID_2"
        },

        uuid: 'REQUEST_UUID_2',

        target_asset: {
          actions: {
            read: "http://api.example.com/api/1/TARGET_ASSET_UUID_2"
          },

          uuid: 'TARGET_ASSET_UUID_2',
          name: 'Target asset 2',
          barcode: 987654321
        }
      }
    ]
  }
  BATCHES_JSON = {
    actions: {
      read: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches",
      first: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches",
      last: "http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches"
    },
    batches: [
      {
        actions: {
          read: "http://api.example.com/api/1/BATCH_UUID_1",
          update: "http://api.example.com/api/1/BATCH_UUID_1"
        },

        uuid: 'BATCH_UUID_1',
        requests: [
          {
            actions: {
              read: "http://api.example.com/api/1/REQUEST_UUID_1"
            },

            uuid: 'REQUEST_UUID_1',

            target_asset: {
              actions: {
                read: "http://api.example.com/api/1/TARGET_ASSET_UUID_1"
              },

              uuid: 'TARGET_ASSET_UUID_1',
              name: 'Target asset 1',
              barcode: 987654321
            }
          },
          {
            actions: {
              read: "http://api.example.com/api/1/REQUEST_UUID_2"
            },

            uuid: 'REQUEST_UUID_2',

            target_asset: {
              actions: {
                read: "http://api.example.com/api/1/TARGET_ASSET_UUID_2"
              },

              uuid: 'TARGET_ASSET_UUID_2',
              name: 'Target asset 2',
              barcode: 987654321
            }
          }
        ]
      }
    ]
  }

  BATCH_CREATE_JSON = {
    batch: {
      requests: [ 'REQUEST_UUID_1', 'REQUEST_UUID_2' ]
    }
  }
  BATCH_UPDATE_JSON = {
    batch: {
      requests: [
        { uuid: 'REQUEST_UUID_1', target_asset: { barcode: 12345678 } }
      ]
    }
  }
  BATCH_JSON = {
    batch: {
      uuid: 'BATCH_UUID_1',
      requests: [

      ]
    }
  }

  def get(url, json)
    stub_request(:get, url).with(REQUEST_HEADERS).
      to_return(:status => 200, :body => json.to_json, :headers => RESPONSE_HEADERS)
  end

  def put(url, sent, received)
    stub_request(:put, url).
      with(REQUEST_HEADERS.merge(:body => sent.to_json)).
      to_return(:status => 200, :body => received.to_json, :headers => RESPONSE_HEADERS)
  end

  def post(url, sent, received)
    stub_request(:post, url).
      with(REQUEST_HEADERS.merge(:body => sent.to_json)).
      to_return(:status => 200, :body => received.to_json, :headers => RESPONSE_HEADERS)
  end

  before(:each) do
    # TODO: Replace these with the test files
    get('http://api.example.com/api/1/', ROOT_JSON)
    get('http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE', PIPELINE_JSON)

    # Now setup the API and the basic pipeline
    api = Sequencescape::Api.new(:url => 'http://api.example.com/api/1/', :cookie => 'testing', :authorisation => 'authorised')
    @pipeline = api.pipeline.find('UUID_FOR_TEST_PIPELINE')
  end

  context 'creating a new batch' do
    before(:each) do
      # TODO: Replace these with the test files
      get('http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/requests', REQUESTS_JSON)
      post('http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches', BATCH_CREATE_JSON, BATCH_JSON)
    end

    it 'sends UUIDs for requests' do
      @pipeline.batches.create!(requests: @pipeline.requests)
    end
  end

  context 'updating an existing batch' do
    before(:each) do
      # TODO: Replace these with the test files
      get('http://api.example.com/api/1/UUID_FOR_TEST_PIPELINE/batches', BATCHES_JSON)
      put('http://api.example.com/api/1/BATCH_UUID_1', BATCH_UPDATE_JSON, BATCH_JSON)

      @batch = @pipeline.batches.first
    end

    context '#save!' do
      it 'only sends the deltas for the requests' do
        @batch.requests.first.target_asset.barcode = 12345678
        @batch.save!
      end
    end

    context '#update_attributes!' do
      it 'requires accepts_nested_attributes_for'
      it 'only sends the deltas for the requests'
    end
  end
end