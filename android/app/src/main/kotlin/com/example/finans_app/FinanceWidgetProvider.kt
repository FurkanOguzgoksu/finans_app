package com.example.finans_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FinanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data from SharedPreferences
                val income = widgetData.getString("monthly_income", "₺0.00")
                val expense = widgetData.getString("monthly_expense", "₺0.00")

                // Set data to views
                setTextViewText(R.id.widget_income, income)
                setTextViewText(R.id.widget_expense, expense)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
