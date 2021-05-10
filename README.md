# Hedgehog

*Note*: This branch is unique as it's a fresh code and it won't be extended further as it was created to support the "build in 15 minutes" teaser/refresher video. Readme below is limited to the functionality that was part of the video.

Repository created to follow along with the [Create a cryptocurrency trading bot in Elixir](https://www.youtube.com/playlist?list=PLxsE19GnjC5Nv1CbeKOiS5YqGqw35aZFJ) course.

Each subsequent video has an assigned git branch that stores a state of the code after it.

For anyone interested in an ebook version of the course, I've published one at [https://www.elixircryptobot.com](https://www.elixircryptobot.com).

## Limit of Liability/Disclaimer of Warranty

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Intial setup

1. Install the required dependencies:

```
$ mix deps.get
...
```

2. Start Postgres instance inside docker:

```
$ docker-compose up -d
Creating hedgehog_db_1 ... done
```

3. Create databases inside the Postgres instance:

```
$ mix ecto.create
The database for Naive.Repo has been created
The database for Streamer.Repo has been created
```

4. Migrate all databases:

```
$ mix ecto.migrate
...
```

5. Seed default settings into the `naive` database:

```
$ cd apps/naive
$ mix run priv/seed_settings.exs
...
```

## Further setup (danger zone)

To connect to the Binance exchange and make real trades the configuration needs to be changed to  as `api_key` and `secret_key` need to be set:

```
# /config/config.exs:L49
config :binance,
  api_key: "insert value here",
  secret_key: "insert value here"
```

## Running

```
iex -S mix

# connect to the Binance and stream into PubSub
Streamer.start_streaming("xrpusdt")

# turn on naive strategy
Naive.start_trading("XRPUSDT")
```