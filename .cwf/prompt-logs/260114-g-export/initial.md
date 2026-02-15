skill-creator skill을 이용해 다음 스킬을 만들고, 현재 repo 구조에 맞게 플러그인으로 추가한다.

---

Google 슬라이드, 독스, 시트 다운로드 스킬

(public 공개된 문서에 한함)

구글 슬라이드
- https://docs.google.com/presentation/d/{id}/export?format={format}
- format: pptx, odp, pdf, txt
- 현재 슬라이드만 가져오는 이미지 export는 지원하지 않음

구글 독스
- https://docs.google.com/document/d/{id}/export?format={format}
- format: docx, odt, pdf, txt, epub, html, md
- 탭이 여러 개면 모든 탭이 하나의 파일로 병합됨

구글 시트
- https://docs.google.com/spreadsheets/d/{id}/export?format={format}
- format: xlsx, ods, pdf, csv, tsv
- csv, tsv는 기본적으로 첫 번째 시트만 다운로드됨. 다른 시트를 원한다면 gid 쿼리 파라미터 추가 필요 (...&gid={sheetId})

curl -L -O -J "https://docs.google.com/{type}/d/{id}/export?format={format}"