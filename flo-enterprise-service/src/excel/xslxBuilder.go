package excel

import (
	"bufio"
	"bytes"

	"github.com/tealeg/xlsx/v3"
)

func CreateWb() *xlsx.File {
	return xlsx.NewFile()
}

func AddSheet(wb *xlsx.File, name string, data [][]string) (err error) {
	sheet, err := wb.AddSheet(name)
	if err != nil {
		return
	}

	for _, rowRaw := range data {
		row := sheet.AddRow()
		for _, field := range rowRaw {
			cell := row.AddCell()
			cell.Value = field
		}
	}
	return
}

func ToReader(wb *xlsx.File) *bytes.Reader {
	var b bytes.Buffer
	writer := bufio.NewWriter(&b)
	wb.Write(writer)
	return bytes.NewReader(b.Bytes())

}
