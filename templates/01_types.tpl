{{if .Table.IsJoinTable -}}
{{else -}}
{{- $varNameSingular := .Table.Name | singular | camelCase -}}
{{- $tableNameSingular := .Table.Name | singular | titleCase -}}
var (
  {{$varNameSingular}}Columns                   = []string{{"{"}}{{.Table.Columns | columnNames | stringMap .StringFuncs.quoteWrap | join ", "}}{{"}"}}
  {{$varNameSingular}}ColumnsWithoutDefault     = []string{{"{"}}{{.Table.Columns | filterColumnsByDefault false | columnNames | stringMap .StringFuncs.quoteWrap | join ","}}{{"}"}}
  {{$varNameSingular}}ColumnsWithDefault        = []string{{"{"}}{{.Table.Columns | filterColumnsByDefault true | columnNames | stringMap .StringFuncs.quoteWrap | join ","}}{{"}"}}
  {{$varNameSingular}}PrimaryKeyColumns         = []string{{"{"}}{{.Table.PKey.Columns | stringMap .StringFuncs.quoteWrap | join ", "}}{{"}"}}
)

type (
  {{$tableNameSingular}}Slice []*{{$tableNameSingular}}
  {{if eq .NoHooks false -}}
  {{$tableNameSingular}}Hook func(boil.Executor, *{{$tableNameSingular}}) error
  {{- end}}

  {{$varNameSingular}}Query struct {
    *boil.Query
  }
)

// Cache for insert and update
var (
  {{$varNameSingular}}Type = reflect.TypeOf(&{{$tableNameSingular}}{})
  {{$varNameSingular}}Mapping = boil.MakeStructMapping({{$varNameSingular}}Type)
  {{$varNameSingular}}InsertCacheMut sync.RWMutex
  {{$varNameSingular}}InsertCache = make(map[string]insertCache)
  {{$varNameSingular}}UpdateCacheMut sync.RWMutex
  {{$varNameSingular}}UpdateCache = make(map[string]updateCache)
)

// Force time package dependency for automated UpdatedAt/CreatedAt.
var _ = time.Second
{{end -}}
