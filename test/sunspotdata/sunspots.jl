using DataFrames
using TimeSeries


const SOURCE_DAILY = "sunspots_daily.csv"
const SOURCE_MONTHLY = "sunspots_monthly.csv"


function get_sunspot_daily_df(sourcefile::String=SOURCE_DAILY)
    df = readtable(sourcefile, separator=';', header=false)
    names!(df, [:Year, :Month, :Day, :DateFloat, :SpotsTotal, :SpotsStd, :NObservations,
                :DefinitiveProvisional])
    # assumes there are no null dates
    df[:Date] = Date.(dropnull(df[:Year]), dropnull(df[:Month]), dropnull(df[:Day]))
    df
end


function get_sunspot_monthly_df(sourcefile::String=SOURCE_MONTHLY)
    df = readtable(sourcefile, separator=';')
    names!(df, [:Year, :Month, :DateFloat, :SpotsMean, :SpotsStd, :NObservations,
                :DefinitiveProvisional])
    days = dropnull(df[:DateFloat])
    years = dropnull(df[:Year])
    days = (days - trunc.(Int64, days))*365  # this is rough but fine for now
    days = Date.(years, 1, 1) + Dates.Day.(days)
    # assumes there are no null dates
    df[:Date] = Date.(years, dropnull(df[:Month]), days)
    df
end


function get_sunspot_daily_ts(df::DataFrame)
    relcols = [:SpotsTotal, :SpotsStd, :NObservations, :DefinitiveProvisional]
    dates = convert(Vector{Date}, df[:Date])
    data = convert(Array, df[relcols])
    TimeArray(dates, data, string.(relcols))
end
get_sunspot_daily_ts(sourcefile::String=SOURCE_DAILY) =
    get_sunspot_daily_ts(get_sunspot_daily_df(sourcefile))
get_sunspot_daily_ts(sourcefile::String=SOURCE_DAILY, col::Union{Symbol, String}) =
    get_sunspot_daily_ts(sourcefile)[string(col)]


function get_sunspot_monthly_ts(df::DataFrame)
    relcols = [:SpotsMean, :SpotsStd, :NObservations, :DefinitiveProvisional]
    dates = convert(Vector{Date}, df[:Date])
    data = convert(Array, df[relcols])
    TimeArray(dates, data, string.(relcols))
end
get_sunspot_monthly_ts(sourcefile::String=SOURCE_MONTHLY) =
    get_sunspot_monthly_ts(get_sunspot_monthly_df(sourcefile))
get_sunspot_monthly_ts(sourcefile::String=SOURCE_MONTHLY, col::Union{Symbol, String}) =
    get_sunspot_monthly_ts(sourcefile)[string(col)]































