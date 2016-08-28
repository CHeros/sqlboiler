{{- if .Table.IsJoinTable -}}
{{- else -}}
  {{- $dot := . -}}
  {{- $table := .Table -}}
  {{- range .Table.ToManyRelationships -}}
    {{- $varNameSingular := .ForeignTable | singular | camelCase -}}
    {{- if (and .ForeignColumnUnique (not .ToJoinTable)) -}}
{{- template "relationship_to_one_setops_helper" (textsFromOneToOneRelationship $dot.PkgName $dot.Tables $table .) -}}
    {{- else -}}
    {{- $rel := textsFromRelationship $dot.Tables $table .}}

// Add{{$rel.Function.Name}} adds the given related objects to the existing relationships
// of the {{$table.Name | singular}}, optionally inserting them as new records.
// Appends related to {{$rel.Function.Receiver}}.R.{{$rel.Function.Name}}.
// Sets related.R.{{$rel.Function.ForeignName}} appropriately.
func ({{$rel.Function.Receiver}} *{{$rel.LocalTable.NameGo}}) Add{{$rel.Function.Name}}(exec boil.Executor, insert bool, related ...*{{$rel.ForeignTable.NameGo}}) error {
  var err error
  for _, rel := range related {
    rel.{{$rel.Function.ForeignAssignment}} = {{$rel.Function.Receiver}}.{{$rel.Function.LocalAssignment}}
    {{if .ForeignColumnNullable -}}
    rel.{{$rel.ForeignTable.ColumnNameGo}}.Valid = true
    {{end -}}
    if insert {
      if err = rel.Insert(exec); err != nil {
        return errors.Wrap(err, "failed to insert into foreign table")
      }
    }{{if not .ToJoinTable}} else {
      if err = rel.Update(exec, "{{.ForeignColumn}}"); err != nil {
        return errors.Wrap(err, "failed to update foreign table")
      }
    }{{end -}}
  }

  {{if .ToJoinTable -}}
  for _, rel := range related {
    query := `insert into "{{.JoinTable}}" ({{.JoinLocalColumn}}, {{.JoinForeignColumn}}) values ($1, $2)`
    values := []interface{}{{"{"}}{{$rel.Function.Receiver}}.{{$rel.LocalTable.ColumnNameGo}}, rel.{{$rel.ForeignTable.ColumnNameGo}}}

    if boil.DebugMode {
      fmt.Fprintln(boil.DebugWriter, query)
      fmt.Fprintln(boil.DebugWriter, values)
    }

    _, err = exec.Exec(query, values...)
    if err != nil {
      return errors.Wrap(err, "failed to insert into join table")
    }
  }
  {{end -}}

  if {{$rel.Function.Receiver}}.R == nil {
    {{$rel.Function.Receiver}}.R = &{{$rel.LocalTable.NameGo}}R{
      {{$rel.Function.Name}}: related,
    }
  } else {
    {{$rel.Function.Receiver}}.R.{{$rel.Function.Name}} = append({{$rel.Function.Receiver}}.R.{{$rel.Function.Name}}, related...)
  }

  {{if .ToJoinTable -}}
  for _, rel := range related {
    if rel.R == nil {
      rel.R = &{{$rel.ForeignTable.NameGo}}R{
        {{$rel.Function.ForeignName}}: {{$rel.LocalTable.NameGo}}Slice{{"{"}}{{$rel.Function.Receiver}}{{"}"}},
      }
    } else {
      rel.R.{{$rel.Function.ForeignName}} = append(rel.R.{{$rel.Function.ForeignName}}, {{$rel.Function.Receiver}})
    }
  }
  {{else -}}
  for _, rel := range related {
    if rel.R == nil {
      rel.R = &{{$rel.ForeignTable.NameGo}}R{
        {{$rel.Function.ForeignName}}: {{$rel.Function.Receiver}},
      }
    } else {
      rel.R.{{$rel.Function.ForeignName}} = {{$rel.Function.Receiver}}
    }
  }
  {{end -}}

  return nil
}
{{- if .ForeignColumnNullable}}

// Set{{$rel.Function.Name}} removes all previously related items of the
// {{$table.Name | singular}} replacing them completely with the passed
// in related items, optionally inserting them as new records.
// Sets {{$rel.Function.Receiver}}.R.{{$rel.Function.ForeignName}}'s {{$rel.Function.Name}} accordingly.
// Replaces {{$rel.Function.Receiver}}.R.{{$rel.Function.Name}} with related.
// Sets related.R.{{$rel.Function.ForeignName}}'s {{$rel.Function.Name}} accordingly.
func ({{$rel.Function.Receiver}} *{{$rel.LocalTable.NameGo}}) Set{{$rel.Function.Name}}(exec boil.Executor, insert bool, related ...*{{$rel.ForeignTable.NameGo}}) error {
  return nil
}

// Remove{{$rel.Function.Name}} relationships from objects passed in.
// Removes related items from R.{{$rel.Function.Name}}.
// Sets related.R.{{$rel.Function.ForeignName}}
func ({{$rel.Function.Receiver}} *{{$rel.LocalTable.NameGo}}) Remove{{$rel.Function.Name}}(exec boil.Executor, related ...*{{$rel.ForeignTable.NameGo}}) error {
  return nil
}
{{end -}}
{{- end -}}{{- /* if unique foreign key */ -}}
{{- end -}}{{- /* range relationships */ -}}
{{- end -}}{{- /* outer if join table */ -}}