package com.p2bble.haru_1min

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class HaruWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
        // 매 갱신마다 다음 자정 리셋 알람을 재예약(멱등) — Doze로 누락돼도 회복
        scheduleMidnightUpdate(context)
    }

    // 위젯 크기가 바뀔 때(리사이즈) 호출 — API 30 이하 반응형 처리에 필요
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_MIDNIGHT_UPDATE -> {
                // 자정 알람 발생 → 모든 위젯을 즉시 다시 그려 어제 수치를 0으로 리셋
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, HaruWidget::class.java))
                for (id in ids) {
                    updateWidget(context, manager, id)
                }
                scheduleMidnightUpdate(context)
            }
            ACTION_ADD_WATER -> handleAddWater(context, intent)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelMidnightUpdate(context)
    }

    companion object {
        private const val ACTION_MIDNIGHT_UPDATE = "com.p2bble.haru_1min.MIDNIGHT_UPDATE"
        private const val MIDNIGHT_REQUEST_CODE = 1001
        private const val ACTION_ADD_WATER = "com.p2bble.haru_1min.ADD_WATER"
        private const val ADD_WATER_REQUEST_CODE = 1002

        // 위젯에 표시할 데이터 묶음 (prefs 1회 읽기)
        private data class WidgetData(
            val dateLabel: String,
            val waterText: String,
            val percent: Int,
            val supplementText: String,
            val supplementTaken: Int,
            val supplementTotal: Int,
            val cupSize: Int
        )

        private fun readData(context: Context): WidgetData {
            val prefs = HomeWidgetPlugin.getData(context)
            val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val savedDate = prefs.getString("water_date", todayKey)
            // 자정이 지나 날짜가 바뀌면 어제 수치 대신 0으로 표시
            val isToday = savedDate == todayKey
            val waterAmount = if (isToday) prefs.getInt("water_amount", 0) else 0
            val waterGoal = prefs.getInt("water_goal", 2000)
            val supplementTaken = if (isToday) prefs.getInt("supplement_taken", 0) else 0
            val supplementTotal = prefs.getInt("supplement_total", 0)
            val cupSize = prefs.getInt("cup_size", 250)

            val percent = if (waterGoal > 0) (waterAmount * 100 / waterGoal).coerceAtMost(100) else 0
            val dateLabel = SimpleDateFormat("M/d (EEE)", Locale.KOREAN).format(Date())
            val supplementText =
                if (supplementTotal == 0) "등록된 영양제 없음"
                else supplementDots(supplementTaken, supplementTotal)

            return WidgetData(
                dateLabel, "${waterAmount}ml / ${waterGoal}ml", percent,
                supplementText, supplementTaken, supplementTotal, cupSize
            )
        }

        // 영양제를 도트로: 복용=● 미복용=○, 최대 6개 표시 후 초과는 "+N"
        private fun supplementDots(taken: Int, total: Int): String {
            val max = 6
            val shown = minOf(total, max)
            val filled = minOf(taken, shown)
            val sb = StringBuilder()
            for (i in 0 until shown) {
                sb.append(if (i < filled) "●" else "○")
                if (i < shown - 1) sb.append(" ")
            }
            if (total > max) sb.append(" +${total - max}")
            return sb.toString()
        }

        // 모든 레이아웃 공통: 물 추가 버튼 + 본문 탭(앱 열기) 클릭 연결
        private fun applyClicks(context: Context, views: RemoteViews, cupSize: Int) {
            // 물 추가는 우리 리시버(ACTION_ADD_WATER)로 직접 전달 → 네이티브에서 즉시 반영.
            // (Dart 백그라운드 엔진 부팅을 기다리지 않으므로 체감 지연 제거)
            views.setOnClickPendingIntent(
                R.id.widget_add_water_btn,
                addWaterPendingIntent(context, cupSize)
            )
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            )
        }

        // 텍스트 기반 레이아웃 공통 바인딩 (확장/와이드 공유 — 동일 id 사용)
        private fun buildTextLayout(context: Context, d: WidgetData, layoutRes: Int): RemoteViews {
            val views = RemoteViews(context.packageName, layoutRes)
            views.setTextViewText(R.id.widget_date, d.dateLabel)
            views.setTextViewText(R.id.widget_water_text, d.waterText)
            views.setTextViewText(R.id.widget_water_percent, "${d.percent}%")
            views.setProgressBar(R.id.widget_water_progress, 100, d.percent, false)
            views.setTextViewText(R.id.widget_supplement_text, d.supplementText)
            applyClicks(context, views, d.cupSize)
            return views
        }

        // 확장(세로 텍스트) — 모든 정보 + 하단 "한 잔 마셨어요" 버튼
        private fun buildExpanded(context: Context, d: WidgetData): RemoteViews =
            buildTextLayout(context, d, R.layout.haru_widget)

        // 와이드(가로 넓고 2행) — 왼쪽 정보 + 오른쪽 큰 버튼
        private fun buildWide(context: Context, d: WidgetData): RemoteViews =
            buildTextLayout(context, d, R.layout.haru_widget_wide)

        // 컴팩트(소형) 레이아웃 — 원형 링 + 물방울/% + 영양제 미니 + 아이콘 "+"
        private fun buildCompact(context: Context, d: WidgetData): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.haru_widget_compact)
            views.setProgressBar(R.id.widget_ring, 100, d.percent, false)
            views.setTextViewText(R.id.widget_ring_percent, "${d.percent}%")
            if (d.supplementTotal == 0) {
                views.setViewVisibility(R.id.widget_supp_mini, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_supp_mini, View.VISIBLE)
                views.setTextViewText(R.id.widget_supp_mini, "💊 ${d.supplementText}")
            }
            applyClicks(context, views, d.cupSize)
            return views
        }

        // 마이크로(1x1) 레이아웃 — 작은 링 + 중앙 "+" 만
        private fun buildMicro(context: Context, d: WidgetData): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.haru_widget_micro)
            views.setProgressBar(R.id.widget_ring, 100, d.percent, false)
            applyClicks(context, views, d.cupSize)
            return views
        }

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val d = readData(context)

            val remoteViews = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+: 크기별 RemoteViews 매핑 → 시스템이 리사이즈 시 자동 선택
                // 1x1=마이크로, 좁은 중간=컴팩트 링, 넓고 2행=와이드(버튼), 넓고 높음=확장
                RemoteViews(
                    mapOf(
                        SizeF(40f, 40f) to buildMicro(context, d),
                        SizeF(120f, 100f) to buildCompact(context, d),
                        SizeF(200f, 110f) to buildWide(context, d),
                        SizeF(200f, 170f) to buildExpanded(context, d)
                    )
                )
            } else {
                // API 30 이하: 최소 너비/높이로 단계 결정
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
                val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
                when {
                    minHeight >= 160 -> buildExpanded(context, d)
                    minHeight >= 100 && minWidth >= 200 -> buildWide(context, d)
                    minHeight >= 100 -> buildCompact(context, d)
                    else -> buildMicro(context, d)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, remoteViews)
        }

        // 물 추가 버튼 → 우리 리시버로 직접 전달하는 PendingIntent (cup_size 동봉)
        private fun addWaterPendingIntent(context: Context, cupSize: Int): PendingIntent {
            val intent = Intent(context, HaruWidget::class.java).apply {
                action = ACTION_ADD_WATER
                // data를 cup_size별로 구분해 PendingIntent가 덮어써지지 않게 함
                data = Uri.parse("haruwidget://add_water?cup_size=$cupSize")
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getBroadcast(context, ADD_WATER_REQUEST_CODE, intent, flags)
        }

        // 물 한 잔 추가: ①네이티브가 prefs를 즉시 올리고 위젯을 바로 갱신(체감 즉시) →
        //              ②Dart 백그라운드 콜백으로 DB에 권위 저장(지연돼도 화면은 이미 반영됨)
        private fun handleAddWater(context: Context, intent: Intent) {
            val cupSize = intent.data?.getQueryParameter("cup_size")?.toIntOrNull() ?: 250

            // ① 낙관적 네이티브 업데이트
            val prefs = HomeWidgetPlugin.getData(context)
            val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val savedDate = prefs.getString("water_date", todayKey)
            // 자정이 지나 날짜가 바뀌었으면 0부터 시작
            val base = if (savedDate == todayKey) prefs.getInt("water_amount", 0) else 0
            prefs.edit()
                .putInt("water_amount", base + cupSize)
                .putString("water_date", todayKey)
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, HaruWidget::class.java))
            for (id in ids) updateWidget(context, manager, id)

            // ② DB 권위 저장 (기존 Dart 경로 재사용; 나중에 같은 값으로 prefs를 덮어써 정합성 유지)
            val uri = Uri.parse("homeWidget://add_water?cup_size=$cupSize")
            try {
                HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
            } catch (e: PendingIntent.CanceledException) {
                // 백그라운드 트리거 실패 시에도 화면(prefs)은 이미 갱신된 상태
            }
        }

        private fun midnightPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, HaruWidget::class.java).apply {
                action = ACTION_MIDNIGHT_UPDATE
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getBroadcast(context, MIDNIGHT_REQUEST_CODE, intent, flags)
        }

        private fun scheduleMidnightUpdate(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            // 다음 자정 +5초 (날짜가 확실히 넘어간 시점)
            val triggerAt = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 5)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis

            val pending = midnightPendingIntent(context)

            // exact alarm 권한이 있으면 정확히, 없으면 inexact로 폴백 (자정 리셋은 초단위 정밀도 불필요)
            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }

            if (canExact) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, pending
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, pending
                )
            }
        }

        private fun cancelMidnightUpdate(context: Context) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            alarmManager.cancel(midnightPendingIntent(context))
        }
    }
}
