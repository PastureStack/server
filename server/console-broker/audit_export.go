package main

import (
	"archive/zip"
	"bytes"
	"encoding/csv"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

type auditExportRow struct {
	Created      string `json:"created"`
	Environment  string `json:"environment"`
	User         string `json:"user"`
	Channel      string `json:"channel"`
	AuthType     string `json:"authenticationType"`
	ClientIP     string `json:"sourceIp"`
	EventType    string `json:"eventType"`
	Description  string `json:"description"`
	ResourceType string `json:"resourceType"`
	ResourceID   string `json:"resourceId"`
}

type auditJSONExport struct {
	GeneratedAt string           `json:"generatedAt"`
	From        string           `json:"from"`
	To          string           `json:"to"`
	Count       int              `json:"count"`
	Records     []auditExportRow `json:"records"`
}

func writeAuditExport(writer http.ResponseWriter, request *http.Request, query auditQuery, result auditResult) error {
	if result.Total > auditMaximumExportRows {
		return &auditHTTPError{Status: http.StatusUnprocessableEntity, Code: "export_too_large", Message: "Narrow the audit log filters to export at most 10,000 records"}
	}

	rows := make([]auditExportRow, 0, len(result.Records))
	for _, record := range result.Records {
		rows = append(rows, auditExportRow{
			Created: auditString(record, "created"), Environment: auditString(record, "environmentDisplayName"),
			User: auditString(record, "actorDisplayName"), Channel: auditString(record, "interactionChannel"),
			AuthType: auditString(record, "authType"), ClientIP: auditString(record, "clientIp"),
			EventType: auditString(record, "eventType"), Description: auditString(record, "description"),
			ResourceType: auditString(record, "resourceType"), ResourceID: auditString(record, "resourceId"),
		})
	}

	format := strings.ToLower(request.URL.Query().Get("format"))
	if format == "" {
		format = "xlsx"
	}
	traditionalChinese := strings.HasPrefix(strings.ToLower(request.Header.Get("Accept-Language")), "zh")
	filenameDate := query.To.UTC().Format("20060102-150405")
	var payload []byte
	var contentType, extension string
	var err error

	switch format {
	case "csv":
		payload, err = buildAuditCSV(rows, traditionalChinese)
		contentType, extension = "text/csv; charset=utf-8", "csv"
	case "json":
		payload, err = json.MarshalIndent(auditJSONExport{
			GeneratedAt: time.Now().UTC().Format(time.RFC3339), From: query.From.Format(time.RFC3339Nano),
			To: query.To.Format(time.RFC3339Nano), Count: len(rows), Records: rows,
		}, "", "  ")
		if err == nil {
			payload = append(payload, '\n')
		}
		contentType, extension = "application/json; charset=utf-8", "json"
	case "xlsx":
		payload, err = buildAuditXLSX(rows, query, traditionalChinese)
		contentType, extension = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx"
	default:
		return &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_export_format", Message: "Audit log export format must be xlsx, csv, or json"}
	}
	if err != nil {
		return err
	}

	writer.Header().Set("Content-Type", contentType)
	writer.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="pasturestack-audit-logs-%s.%s"`, filenameDate, extension))
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("Pragma", "no-cache")
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	writer.Header().Set("Content-Length", strconv.Itoa(len(payload)))
	_, err = writer.Write(payload)
	return err
}

func buildAuditCSV(rows []auditExportRow, traditionalChinese bool) ([]byte, error) {
	buffer := &bytes.Buffer{}
	buffer.Write([]byte{0xEF, 0xBB, 0xBF})
	writer := csv.NewWriter(buffer)
	if err := writer.Write(auditExportHeaders(traditionalChinese)); err != nil {
		return nil, err
	}
	for _, row := range rows {
		values := auditExportValues(row, traditionalChinese)
		for index := range values {
			values[index] = safeSpreadsheetText(values[index])
		}
		if err := writer.Write(values); err != nil {
			return nil, err
		}
	}
	writer.Flush()
	if err := writer.Error(); err != nil {
		return nil, err
	}
	return buffer.Bytes(), nil
}

func buildAuditXLSX(rows []auditExportRow, query auditQuery, traditionalChinese bool) ([]byte, error) {
	buffer := &bytes.Buffer{}
	archive := zip.NewWriter(buffer)
	files := map[string]string{
		"[Content_Types].xml": `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
			`<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">` +
			`<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>` +
			`<Default Extension="xml" ContentType="application/xml"/>` +
			`<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>` +
			`<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>` +
			`<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>` +
			`<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>` +
			`<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>`,
		"_rels/.rels": `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
			`<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
			`<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>` +
			`<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>` +
			`<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>`,
		"xl/workbook.xml": `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
			`<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">` +
			`<sheets><sheet name="Audit Logs" sheetId="1" r:id="rId1"/></sheets></workbook>`,
		"xl/_rels/workbook.xml.rels": `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
			`<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
			`<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>` +
			`<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>`,
		"xl/styles.xml":            auditXLSXStyles(),
		"xl/worksheets/sheet1.xml": auditXLSXSheet(rows, traditionalChinese),
		"docProps/app.xml": `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
			`<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>PastureStack</Application></Properties>`,
		"docProps/core.xml": fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`+
			`<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">`+
			`<dc:title>PastureStack Audit Logs</dc:title><dc:creator>PastureStack</dc:creator><dc:description>%s</dc:description>`+
			`<dcterms:created xsi:type="dcterms:W3CDTF">%s</dcterms:created></cp:coreProperties>`,
			xmlText(query.From.Format(time.RFC3339)+" - "+query.To.Format(time.RFC3339)), time.Now().UTC().Format(time.RFC3339)),
	}
	order := []string{"[Content_Types].xml", "_rels/.rels", "docProps/app.xml", "docProps/core.xml", "xl/workbook.xml", "xl/_rels/workbook.xml.rels", "xl/styles.xml", "xl/worksheets/sheet1.xml"}
	for _, name := range order {
		entry, err := archive.Create(name)
		if err != nil {
			return nil, err
		}
		if _, err := entry.Write([]byte(files[name])); err != nil {
			return nil, err
		}
	}
	if err := archive.Close(); err != nil {
		return nil, err
	}
	return buffer.Bytes(), nil
}

func auditXLSXStyles() string {
	return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
		`<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">` +
		`<fonts count="2"><font><sz val="11"/><name val="Aptos"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Aptos"/></font></fonts>` +
		`<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF0B7895"/><bgColor indexed="64"/></patternFill></fill></fills>` +
		`<borders count="2"><border/><border><left style="thin"><color rgb="FFD7E0E4"/></left><right style="thin"><color rgb="FFD7E0E4"/></right><top style="thin"><color rgb="FFD7E0E4"/></top><bottom style="thin"><color rgb="FFD7E0E4"/></bottom></border></borders>` +
		`<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>` +
		`<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center"/></xf><xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf></cellXfs>` +
		`<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>`
}

func auditXLSXSheet(rows []auditExportRow, traditionalChinese bool) string {
	buffer := &strings.Builder{}
	buffer.WriteString(`<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`)
	buffer.WriteString(`<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">`)
	buffer.WriteString(`<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>`)
	buffer.WriteString(`<cols><col min="1" max="1" width="23" customWidth="1"/><col min="2" max="4" width="20" customWidth="1"/><col min="5" max="6" width="18" customWidth="1"/><col min="7" max="7" width="28" customWidth="1"/><col min="8" max="8" width="48" customWidth="1"/><col min="9" max="10" width="24" customWidth="1"/></cols>`)
	buffer.WriteString(`<sheetData>`)
	writeXLSXRow(buffer, 1, auditExportHeaders(traditionalChinese), 1)
	for index, row := range rows {
		values := auditExportValues(row, traditionalChinese)
		for valueIndex := range values {
			values[valueIndex] = safeSpreadsheetText(values[valueIndex])
		}
		writeXLSXRow(buffer, index+2, values, 2)
	}
	buffer.WriteString(`</sheetData>`)
	lastRow := len(rows) + 1
	buffer.WriteString(fmt.Sprintf(`<autoFilter ref="A1:J%d"/>`, lastRow))
	buffer.WriteString(`</worksheet>`)
	return buffer.String()
}

func writeXLSXRow(buffer *strings.Builder, rowNumber int, values []string, style int) {
	buffer.WriteString(fmt.Sprintf(`<row r="%d"%s>`, rowNumber, map[bool]string{true: ` ht="24" customHeight="1"`, false: ""}[rowNumber == 1]))
	for index, value := range values {
		reference := xlsxColumn(index+1) + strconv.Itoa(rowNumber)
		buffer.WriteString(fmt.Sprintf(`<c r="%s" t="inlineStr" s="%d"><is><t xml:space="preserve">%s</t></is></c>`, reference, style, xmlText(value)))
	}
	buffer.WriteString(`</row>`)
}

func xlsxColumn(index int) string {
	result := ""
	for index > 0 {
		index--
		result = string(rune('A'+index%26)) + result
		index /= 26
	}
	return result
}

func xmlText(value string) string {
	buffer := &bytes.Buffer{}
	_ = xml.EscapeText(buffer, []byte(value))
	return buffer.String()
}

func auditExportHeaders(traditionalChinese bool) []string {
	if traditionalChinese {
		return []string{"時間", "環境", "使用者", "操作管道", "驗證方式", "來源 IP", "事件類型", "描述", "資源類型", "資源 ID"}
	}
	return []string{"Time", "Environment", "User", "Channel", "Authentication", "Source IP", "Event Type", "Description", "Resource Type", "Resource ID"}
}

func auditExportValues(row auditExportRow, traditionalChinese bool) []string {
	channel := row.Channel
	if traditionalChinese {
		channel = map[string]string{"web_ui": "WebUI", "public_api": "API", "automation": "自動化", "system_internal": "系統內部", "unknown": "未知"}[row.Channel]
		if channel == "" {
			channel = "未知"
		}
	}
	return []string{row.Created, row.Environment, row.User, channel, row.AuthType, row.ClientIP, row.EventType, row.Description, row.ResourceType, row.ResourceID}
}

func safeSpreadsheetText(value string) string {
	trimmed := strings.TrimLeft(value, " \u00a0")
	if trimmed == "" {
		return value
	}
	switch trimmed[0] {
	case '=', '+', '-', '@', '\t', '\r':
		return "'" + value
	default:
		return value
	}
}
