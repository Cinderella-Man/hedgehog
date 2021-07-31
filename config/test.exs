import Config

config :core,
  logger: Test.LoggerMock,
  pubsub_client: Test.PubSubMock

config :naive,
  binance_client: Test.BinanceMock,
  leader: Test.Naive.LeaderMock
