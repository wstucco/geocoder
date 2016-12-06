defmodule Geocoder do
  use Application

  @pool_name :geocoder_workers
  @default_config [worker_module: Geocoder.Worker, name: {:local, @pool_name}]

  def pool_name, do: @pool_name
  def worker_pool_config do
    config = Application.get_env(:geocoder, :worker_pool_config) || []
    Keyword.merge(config, @default_config)
  end

  def worker_config do
    Application.get_env(:geocoder, Geocoder.Worker) || []
  end

  def store_config do
    Application.get_env(:geocoder, Geocoder.Store) || []
  end

  def start(_type, _opts) do
    import Supervisor.Spec

    children = [
      :poolboy.child_spec(pool_name, worker_pool_config, worker_config),
      worker(Geocoder.Store, [store_config])
    ]

    options = [
      strategy: :one_for_one,
      name: Geocoder.Supervisor
    ]

    Supervisor.start_link(children, options)
  end

  alias Geocoder.Worker

  def call(opts) when is_list(opts), do: Worker.geocode(opts)

  def call(q, opts \\ [])
  def call(q, opts) when is_binary(q), do: Worker.geocode(opts ++ [address: q])
  def call(q = {lat,lon}, opts), do: Worker.reverse_geocode(opts ++ [lat: lat, lon: lon, latlng: q])
  def call(%{lat: lat, lon: lon}, opts), do: call({lat, lon}, opts)

  def call_list(q, opts \\ [])
  def call_list(q, opts) when is_binary(q), do: Worker.geocode_list(opts ++ [address: q])
  def call_list(q = {_,_}, opts), do: Worker.reverse_geocode_list(opts ++ [latlng: q])
  def call_list(%{lat: lat, lon: lon}, opts), do: call_list({lat, lon}, opts)
end
